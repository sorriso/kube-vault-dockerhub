#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./Initial_root_token.txt)

export VAULT_ADDR=http://vault.kube.local



echo ""
echo "Enable CORS"
echo ""



curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
   --data '{"allowed_origins": "*", "allowed_headers": "X-Custom-Header"}' \
  $VAULT_ADDR/v1/sys/config/cors | jq



echo ""
echo "Building ROOT CA"
echo ""



echo ""
echo "enabling engine pki"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki

echo ""
echo "adding secret"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"max_lease_ttl":"87600h"}' \
   $VAULT_ADDR/v1/sys/mounts/pki/tune

echo ""
echo "creating CA"
echo ""

tee payload.json <<EOF
{
  "common_name": "local",
  "issuer_name": "root-local",
  "ttl": "87600h"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload.json \
   $VAULT_ADDR/v1/pki/root/generate/internal \
   | jq -r ".data.certificate" > root_local_ca.crt

rm payload.json

 echo ""
 echo "configuring roles"
 echo ""

 curl \
     --silent \
     --request PUT \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     --header "X-Vault-Request: true" \
     --data '{"allow_any_name":"true", "issuer_ref": "root-local"}' \
     $VAULT_ADDR/v1/pki/roles/root-local-role

echo ""
echo "configuring url"
echo ""

tee payload-url.json <<EOF
{
  "issuing_certificates": "$VAULT_ADDR/v1/pki/ca",
  "crl_distribution_points": "$VAULT_ADDR/v1/pki/crl"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-url.json \
   $VAULT_ADDR/v1/pki/config/urls

rm payload-url.json

echo ""
echo "request a cert"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"common_name": "test.local", "ttl": "24h"}' \
    $VAULT_ADDR/v1/pki/issue/root-local-role | jq



rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
