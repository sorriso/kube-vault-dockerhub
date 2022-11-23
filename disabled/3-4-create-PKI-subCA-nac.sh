#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local



echo ""
echo "Building INTERMEDIATE CA pki_nac"
echo ""



echo ""
echo "enabling engine pki"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_nac

echo ""
echo "adding secret"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"43800h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_nac/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_nac.json <<EOF
{
  "common_name": "pki_nac Intermediate Authority",
  "issuer_name": "pki_nac-intermediate"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_nac.json \
    $VAULT_ADDR/v1/pki_nac/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_nac_intermediate.csr

rm payload-pki_nac.json

 echo ""
 echo "signing intermediate"
 echo ""

tee payload-pki_nac-cert.json <<EOF
{
  "csr": $(cat pki_nac_intermediate.csr),
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_nac-cert.json \
    $VAULT_ADDR/v1/pki/root/sign-intermediate \
    | jq '.data | .certificate' > pki_nac_intermediate.cert.pem

rm payload-pki_nac-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_nac-signed.json <<EOF
{
  "certificate": $(cat pki_nac_intermediate.cert.pem)
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_nac-signed.json \
    $VAULT_ADDR/v1/pki_nac/intermediate/set-signed \
    | jq

rm payload-pki_nac-signed.json

echo ""
echo "configuring roles"
echo ""

tee payload-pki_nac-role.json <<EOF
{
  "allowed_domains": "cluster.local",
  "allow_subdomains": true,
  "issuer_ref": "pki_nac-intermediate",
  "max_ttl": "720h"
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_nac-role.json \
   $VAULT_ADDR/v1/pki_nac/roles/pki_nac-role

rm payload-pki_nac-role.json

echo ""
echo "request certificate"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.cluster.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki_nac/issue/pki_nac-role | jq

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
