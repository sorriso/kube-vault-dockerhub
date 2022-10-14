#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | grep root_token | awk '{print $2}' | tr -d '"')

export VAULT_ADDR=http://localhost:52100
#export VAULT_ADDR=http://vault.kube.local



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
  "max_ttl": "720h"
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
    $VAULT_ADDR/v1/pki_kube/issue/pki_kube-role | jq > test.kube.local.json




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
    $VAULT_ADDR/v1/pki_cluster/issue/pki_cluster-role | jq > test.cluster.local.json

rm -f *.crt
rm -f *.csr
rm -f *.pem
rm -f test*.json
