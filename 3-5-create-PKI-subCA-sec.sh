#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local



echo ""
echo "Building INTERMEDIATE CA pki_sec"
echo ""



echo ""
echo "enabling engine pki"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_sec

echo ""
echo "adding secret"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"43800h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_sec/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_sec.json <<EOF
{
  "common_name": "pki_sec Intermediate Authority",
  "issuer_name": "pki_sec-intermediate"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_sec.json \
    $VAULT_ADDR/v1/pki_sec/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_sec_intermediate.csr

rm payload-pki_sec.json

 echo ""
 echo "signing intermediate"
 echo ""

tee payload-pki_sec-cert.json <<EOF
{
  "csr": $(cat pki_sec_intermediate.csr),
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_sec-cert.json \
    $VAULT_ADDR/v1/pki/root/sign-intermediate \
    | jq '.data | .certificate' > pki_sec_intermediate.cert.pem

rm payload-pki_sec-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_sec-signed.json <<EOF
{
  "certificate": $(cat pki_sec_intermediate.cert.pem)
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_sec-signed.json \
    $VAULT_ADDR/v1/pki_sec/intermediate/set-signed \
    | jq

rm payload-pki_sec-signed.json

echo ""
echo "configuring roles"
echo ""

tee payload-pki_sec-role.json <<EOF
{
  "allowed_domains": "cluster.local",
  "allow_subdomains": true,
  "issuer_ref": "pki_sec-intermediate",
  "max_ttl": "720h"
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_sec-role.json \
   $VAULT_ADDR/v1/pki_sec/roles/pki_sec-role

rm payload-pki_sec-role.json

echo ""
echo "updating SubCA_sec with SubCA_sec manually created previously"
echo ""

cp ./certs/subca/payload-subcabundle.json ./payload-subcabundle.json

curl -k  \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data "@payload-subcabundle.json" \
  $VAULT_ADDR/v1/pki_sec/config/ca

rm -f ./payload-subcabundle.json

echo ""
echo "request certificate"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.cluster.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki_sec/issue/pki_sec-role | jq   > test-cert.json

ISSUER=$(cat ./test-cert.json | jq -r ".data.issuing_ca")
CAISSUER=$(cat ./certs/ca/ca.pem)
cp ./test-cert.json ./certs/subca/test-cert.json

tee ./certs/subca/bundle.pem <<EOF
$ISSUER
$CAISSUER
EOF

BUNDLE=$(cat ./certs/subca/bundle.pem | base64 )
tee ./certs/subca/bundle64.pem <<EOF
$BUNDLE
EOF

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
