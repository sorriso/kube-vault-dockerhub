#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./Initial_root_token.txt)

export VAULT_ADDR=http://vault.kube.local



echo ""
echo "Building INTERMEDIATE CA pki_cluster"
echo ""



echo ""
echo "enabling engine pki"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_cluster

echo ""
echo "adding secret"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"43800h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_cluster/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_cluster.json <<EOF
{
  "common_name": "pki_cluster Intermediate Authority",
  "issuer_name": "pki_cluster-intermediate"
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_cluster.json \
    $VAULT_ADDR/v1/pki_cluster/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_cluster_intermediate.csr

rm payload-pki_cluster.json

 echo ""
 echo "signing intermediate"
 echo ""

tee payload-pki_cluster-cert.json <<EOF
{
  "csr": $(cat pki_cluster_intermediate.csr),
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_cluster-cert.json \
    $VAULT_ADDR/v1/pki/root/sign-intermediate \
    | jq '.data | .certificate' > pki_cluster_intermediate.cert.pem

rm payload-pki_cluster-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_cluster-signed.json <<EOF
{
  "certificate": $(cat pki_cluster_intermediate.cert.pem)
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_cluster-signed.json \
    $VAULT_ADDR/v1/pki_cluster/intermediate/set-signed \
    | jq

rm payload-pki_cluster-signed.json

echo ""
echo "configuring roles"
echo ""

tee payload-pki_cluster-role.json <<EOF
{
  "allowed_domains": "cluster.local",
  "allow_subdomains": true,
  "issuer_ref": "pki_cluster-intermediate",
  "max_ttl": "720h"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_cluster-role.json \
   $VAULT_ADDR/v1/pki_cluster/roles/pki_cluster-role

rm payload-pki_cluster-role.json

echo ""
echo "request certificate"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.cluster.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki_cluster/issue/pki_cluster-role | jq

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
