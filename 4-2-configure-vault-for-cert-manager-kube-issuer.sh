#!/bin/bash
# https://developer.hashicorp.com/vault/api-docs/secret/pki#submit-ca-information

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local

echo "*****************************************************************************************************************************************"
echo "Configuration pki_kube-issuer"
echo ""

kubectl delete -f cert-manager-pki_kube

echo ""
echo "Create dedicated policy"
echo ""

tee payload-issuer-kube.json <<EOF
{
  "policy": "path \"pki_kube/*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"] }"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-issuer-kube.json \
    $VAULT_ADDR/v1/sys/policy/pki_kube-issuer-policy

rm -f payload-issuer-kube.json

echo ""
echo "List policy"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/sys/policy/pki_kube-issuer-policy | jq

echo ""
echo "Create role"
echo ""

tee payload-role-kube.json <<EOF
{
    "policies": "pki_kube-issuer-policy",
    "token_ttl": "180m",
    "token_max": "300m"
}
EOF
#"secret_id_ttl": "30m",
#"token_num_uses": "0",
#"secret_id_num_uses": "0",

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-role-kube.json \
    $VAULT_ADDR/v1/auth/approle/role/pki_kube-issuer-role

echo ""
echo "List approle / role"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/auth/approle/role/pki_kube-issuer-role | jq

rm -f payload-role-kube.json

echo ""
echo "Get ROLE"
echo ""

export ROLE=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    $VAULT_ADDR/v1/auth/approle/role/pki_kube-issuer-role | jq )

echo "ROLE: $ROLE"

echo ""
echo "Get ROLE_ID"
echo ""

export ROLE_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    $VAULT_ADDR/v1/auth/approle/role/pki_kube-issuer-role/role-id | \
                    jq -r '.data.role_id' )

echo "ROLE_ID: $ROLE_ID"

echo ""
echo "Get SECRET_ID"
echo ""

export SECRET_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    --request POST \
                    $VAULT_ADDR/v1/auth/approle/role/pki_kube-issuer-role/secret-id | \
                    jq -r '.data.secret_id' )
echo "SECRET_ID: $SECRET_ID"

export SECRET_ID64=$(echo $SECRET_ID | base64 )

echo "SECRET_ID64: $SECRET_ID64"

echo ""
echo "Testing appRole login"
echo ""

tee payload_login_kube.json <<EOF
{
 "role_id": "${ROLE_ID}",
 "secret_id": "${SECRET_ID}"
}
EOF

#curl -k --request POST --data @payload_login_kube.json $VAULT_ADDR/v1/auth/approle/login | jq

rm -f payload_login_kube.json

echo ""
echo "Create secret approle yaml file"
echo ""

rm -f cert-manager-pki_kube/cert-manager-secret-approle-pki_kube.yaml
tee cert-manager-pki_kube/cert-manager-secret-approle-pki_kube.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-pki-kube
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-kube
type: Opaque
stringData:
  SECRET_ID: ${SECRET_ID}
  SECRET_ID64: ${SECRET_ID64}
EOF

kubectl apply -f cert-manager-pki_kube/cert-manager-secret-approle-pki_kube.yaml

echo ""
echo "Create vault issuer yaml file"
echo ""

rm -f cert-manager-pki_kube/cert-manager-pki_kube-ClusterIssuer.yaml

CABUNDLE=$(cat ./certs/subca/dundle.pem | base64)
tee cert-manager-pki_kube/cert-manager-pki_kube-ClusterIssuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-pki-kube-clusterissuer
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-kube
spec:
  vault:
    path: pki_kube/sign/pki_kube-role
    server: https://vault-service
    caBundle: $CABUNDLE
    auth:
      appRole:
        path: approle
        roleId: ${ROLE_ID}
        secretRef:
          name: cert-manager-pki-kube
          key: SECRET_ID
EOF

kubectl apply -f cert-manager-pki_kube/cert-manager-pki_kube-ClusterIssuer.yaml

echo ""
echo "Get issuer list"
echo ""

sleep 5

kubectl get ClusterIssuer -n vault-ns -o wide
