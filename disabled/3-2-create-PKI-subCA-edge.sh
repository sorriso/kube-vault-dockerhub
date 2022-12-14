#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local


echo ""
echo "Building INTERMEDIATE CA pki_edge"
echo ""





echo ""
echo "enabling engine pki"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_edge

echo ""
echo "adding secret"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"43800h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_edge/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_edge.json <<EOF
{
  "common_name": "pki_edge Intermediate Authority",
  "issuer_name": "pki_edge-intermediate"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_edge.json \
    $VAULT_ADDR/v1/pki_edge/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_edge_intermediate.csr

rm payload-pki_edge.json

 echo ""
 echo "signing intermediate"
 echo ""

tee payload-pki_edge-cert.json <<EOF
{
  "csr": $(cat pki_edge_intermediate.csr),
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_edge-cert.json \
    $VAULT_ADDR/v1/pki/root/sign-intermediate \
    | jq '.data | .certificate' > pki_edge_intermediate.cert.pem

rm payload-pki_edge-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_edge-signed.json <<EOF
{
  "certificate": $(cat pki_edge_intermediate.cert.pem)
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_edge-signed.json \
    $VAULT_ADDR/v1/pki_edge/intermediate/set-signed \
    | jq

rm payload-pki_edge-signed.json

echo ""
echo "configuring roles"
echo ""

tee payload-pki_edge-role.json <<EOF
{
  "allowed_domains": "kube.local",
  "allow_subdomains": true,
  "issuer_ref": "pki_edge-intermediate",
  "max_ttl": "72h"
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_edge-role.json \
   $VAULT_ADDR/v1/pki_edge/roles/pki_edge-role

rm payload-pki_edge-role.json

echo ""
echo "request certificate"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.kube.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki_edge/issue/pki_edge-role | jq > ./test-cert.json

ISSUER=$(cat ./test-cert.json | jq -r ".data.issuing_ca")
CAISSUER=$(cat ./certs/ca/ca.pem)
cp ./test-cert.json ./certs/edge/test-cert.json

tee ./certs/edge/bundle.pem <<EOF
$ISSUER
$CAISSUER
EOF

BUNDLE=$(cat ./certs/edge/bundle.pem | base64 )
tee ./certs/edge/bundle64.pem <<EOF
$BUNDLE
EOF

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
