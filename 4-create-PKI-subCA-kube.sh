#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./Initial_root_token.txt)

export VAULT_ADDR=http://vault.kube.local


echo ""
echo "Building INTERMEDIATE CA pki_kube"
echo ""





echo ""
echo "enabling engine pki"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_kube

echo ""
echo "adding secret"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"43800h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_kube/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_kube.json <<EOF
{
  "common_name": "pki_kube Intermediate Authority",
  "issuer_name": "pki_kube-intermediate"
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_kube.json \
    $VAULT_ADDR/v1/pki_kube/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_kube_intermediate.csr

rm payload-pki_kube.json

 echo ""
 echo "signing intermediate"
 echo ""

tee payload-pki_kube-cert.json <<EOF
{
  "csr": $(cat pki_kube_intermediate.csr),
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_kube-cert.json \
    $VAULT_ADDR/v1/pki/root/sign-intermediate \
    | jq '.data | .certificate' > pki_kube_intermediate.cert.pem

rm payload-pki_kube-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_kube-signed.json <<EOF
{
  "certificate": $(cat pki_kube_intermediate.cert.pem)
}
EOF

curl \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_kube-signed.json \
    $VAULT_ADDR/v1/pki_kube/intermediate/set-signed \
    | jq

rm payload-pki_kube-signed.json

echo ""
echo "configuring roles"
echo ""

tee payload-pki_kube-role.json <<EOF
{
  "allowed_domains": "kube.local",
  "allow_subdomains": true,
  "issuer_ref": "pki_kube-intermediate",
  "max_ttl": "72h"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_kube-role.json \
   $VAULT_ADDR/v1/pki_kube/roles/pki_kube-role

rm payload-pki_kube-role.json

echo ""
echo "request certificate"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.kube.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki_kube/issue/pki_kube-role | jq


rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
