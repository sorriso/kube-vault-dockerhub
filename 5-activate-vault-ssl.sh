#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=http://localhost:52100
#export VAULT_ADDR=http://vault.kube.local


tee vault-ssl.yaml <<EOF
{
    "common_name": "vault.kube.local",
    "ttl": "500000h"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @vault-ssl.yaml \
    $VAULT_ADDR/v1/pki_kube/issue/pki_kube-role | jq > vault-ssl.json

SSL_CA=$(cat ./vault-ssl.json | jq -r '.data.ca_chain[0]' | sed 's/^/    /')

SSL_CA_SUB=$(cat ./vault-ssl.json | jq -r '.data.issuing_ca' | sed 's/^/    /')

SSL_CERT=$(cat ./vault-ssl.json | jq -r '.data.certificate' | sed 's/^/    /')

SSL_KEY=$(cat ./vault-ssl.json | jq -r '.data.private_key' | sed 's/^/    /')

echo "$SSL_CERT"  > domain.txt
ALL="$(cat ./domain.txt | sed 's/\"//g')"

echo "$SSL_KEY" > domain.txt
SSL_KEY=$(cat ./domain.txt | sed 's/\"//g')

echo "$SSL_CA"  > domain.txt
echo "$SSL_CA_SUB"  >> domain.txt
SSL_CA_BUNDLE="$(cat ./domain.txt | sed 's/\"//g')"

rm -f domain.txt

tee vault-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-secret
  namespace: vault-ns
  labels:
    app: vault
type: Opaque
stringData:
  SSL_CERT_BUNDLE: |
$ALL
  SSL_KEY: |
$SSL_KEY
  SSL_CA_BUNDLE: |
$SSL_CA_BUNDLE
EOF

kubectl apply -f vault-secret.yaml

cp vault-secret.yaml ./vault/vault-secret.yaml

rm -f vault-ssl.yaml
rm -f vault-ssl.json
rm -f vault-secret.yaml

tee vault-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-configmap
  namespace: vault-ns
  labels:
    app: vault
data:
  extraconfig-from-values.hcl: |-
    disable_cache = true
    disable_mlock = true
    ui = true

    listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_disable = 1
    }

    listener "tcp" {
        address = "[::]:8300"
        tls_disable = 0
        tls_cert_file = "/cert/domain.pem"
        tls_key_file = "/cert/domain.key"
        tls_min_version = "tls12"
        tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        tls_prefer_server_cipher_suites = true
    }

    storage "file" {
      path = "/vault/data"
    }

    max_lease_ttl = "10h"
    default_lease_ttl = "10h"
#    service_registration "kubernetes" {}
EOF

kubectl apply -f vault-config.yaml

cp vault-config.yaml ./vault/vault-configmap.yaml

rm -f vault-config.yaml

cd vault

sed -i '' 's,http://127.0.0.1:8200,https://vault.kube.local,g' vault-deployment.yaml
sed -i '' 's,http://$(POD_IP):8200,https://vault.kube.local,g' vault-deployment.yaml



kubectl -n vault-ns delete pods vault-0
