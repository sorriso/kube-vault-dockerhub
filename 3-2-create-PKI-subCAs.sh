#!/bin/bash

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local

function createSubPKIinVault () {
VAULT_TOKEN=$1
VAULT_ADDR=$2
pkiName=$3

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

echo ""
echo "Building INTERMEDIATE CA pki_$pkiName"
echo ""

echo ""
echo "enabling engine pki"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data '{"type":"pki"}' \
   $VAULT_ADDR/v1/sys/mounts/pki_$pkiName

echo ""
echo "Tuning pki_$pkiName config"
echo ""

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"max_lease_ttl":"43800h"}' \
  $VAULT_ADDR/v1/sys/mounts/pki_$pkiName/tune

echo ""
echo "creating csr"
echo ""

tee payload-pki_auth.json <<EOF
{
"common_name": "pki_$pkiName Intermediate Authority",
"issuer_name": "pki_$pkiName-intermediate"
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_$pkiName.json \
    $VAULT_ADDR/v1/pki_$pkiName/intermediate/generate/internal \
    | jq -c '.data | .csr' > pki_$pkiName-intermediate.csr

rm payload-pki_auth.json

echo ""
echo "signing intermediate"
echo ""

tee payload-pki_$pkiName-cert.json <<EOF
{
 "csr": $(cat pki_$pkiName-intermediate.csr),
 "format": "pem_bundle",
 "ttl": "43800h"
}
EOF

curl -k \
   --silent \
   --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_$pkiName-cert.json \
   $VAULT_ADDR/v1/pki/root/sign-intermediate \
   | jq '.data | .certificate' > pki_$pkiName-intermediate.cert.pem

rm payload-pki_$pkiName-cert.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_$pkiName-signed.json <<EOF
{
  "certificate": $(cat pki_$pkiName-intermediate.cert.pem)
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_$pkiName-signed.json \
    $VAULT_ADDR/v1/pki_$pkiName/intermediate/set-signed \
    | jq

rm payload-pki_$pkiName-signed.json

echo ""
echo "importing intermediate cert"
echo ""

tee payload-pki_$pkiName-signed.json <<EOF
{
  "certificate": $(cat pki_$pkiName-intermediate.cert.pem)
}
EOF

curl -k \
    --silent \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_$pkiName-signed.json \
    $VAULT_ADDR/v1/pki_$pkiName/intermediate/set-signed \
    | jq

rm payload-pki_$pkiName-signed.json


echo ""
echo "configuring roles"
echo ""

case $pkiName in
  "auth")
    domain="cluster.local"
    ;;
  "cert")
    domain="cluster.local"
    ;;
  "cluster")
    domain="cluster.local"
    ;;
  "edge")
    domain="kube.local"
    ;;
  "nac")
    domain="nac.local"
    ;;
  *)
    domain="kube.local"
    ;;
esac

tee payload-pki_$pkiName-role.json <<EOF
{
  "allowed_domains": "$domain",
  "allow_subdomains": true,
  "issuer_ref": "pki_$pkiName-intermediate",
  "max_ttl": "720h"
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
   --request POST \
   --data @payload-pki_$pkiName-role.json \
   $VAULT_ADDR/v1/pki_$pkiName/roles/pki_$pkiName-role

rm payload-pki_$pkiName-role.json

echo ""
echo "updating SubCA_auth with SubCA_auth manually created previously"
echo ""

cp ./certs/subca-$pkiName/payload-subcabundle.json ./payload-subcabundle.json

curl -k  \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data "@payload-subcabundle.json" \
  $VAULT_ADDR/v1/pki_$pkiName/config/ca

rm -f ./payload-subcabundle.json

echo ""
echo "requesting certificate"
echo ""

case $pkiName in
  "auth")
    mycert="test1.cluster.local"
    ;;
  "cert")
    mycert="test2.cluster.local"
    ;;
  "cluster")
    mycert="test3.cluster.local"
    ;;
  "edge")
    mycert="test4.kube.local"
    ;;
  "nac")
    mycert="test5.nac.local"
    ;;
  *)
    mycert="test.kube.local"
    ;;
esac

tee payload-pki_$pkiName-cert.json <<EOF
{
  "common_name": "$mycert",
  "ttl": "24h"
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-pki_$pkiName-cert.json \
    $VAULT_ADDR/v1/pki_$pkiName/issue/pki_$pkiName-role | jq   > test-cert.json

rm -f ./payload-pki_$pkiName-cert.json

ISSUER=$(cat ./test-cert.json | jq -r ".data.issuing_ca")
CAISSUER=$(cat ./certs/ca/ca.pem)
cp ./test-cert.json ./certs/subca-$pkiName/test-cert.json

tee ./certs/subca-$pkiName/bundle.pem <<EOF
$ISSUER
$CAISSUER
EOF

BUNDLE=$(cat ./certs/subca-$pkiName/bundle.pem | base64 )
tee ./certs/subca-$pkiName/bundle64.pem <<EOF
$BUNDLE
EOF

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json

}

createSubPKIinVault $VAULT_TOKEN $VAULT_ADDR "auth"

createSubPKIinVault $VAULT_TOKEN $VAULT_ADDR "cert"

createSubPKIinVault $VAULT_TOKEN $VAULT_ADDR "cluster"

createSubPKIinVault $VAULT_TOKEN $VAULT_ADDR "edge"

createSubPKIinVault $VAULT_TOKEN $VAULT_ADDR "nac"
