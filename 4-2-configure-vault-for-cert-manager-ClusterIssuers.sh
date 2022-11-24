#!/bin/bash

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local

function createVaultClusterIssuer () {
VAULT_TOKEN=$1
VAULT_ADDR=$2
pkiName=$3

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr


echo "*****************************************************************************************************************************************"
echo "Configuration pki_$pkiName-issuer"
echo ""

kubectl delete -f cert-manager-pki_$pkiName

echo ""
echo "Create dedicated policy"
echo ""

tee payload-issuer-$pkiName.json <<EOF
{
  "policy": "path \"pki_$pkiName/*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"] }"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-issuer-$pkiName.json \
    $VAULT_ADDR/v1/sys/policy/pki_$pkiName-issuer-policy

rm -f payload-issuer-$pkiName.json


echo ""
echo "List policy"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/sys/policy/pki_$pkiName-issuer-policy | jq


echo ""
echo "Create role"
echo ""

tee payload-role-$pkiName.json <<EOF
{
    "policies": "pki_$pkiName-issuer-policy",
    "token_ttl": "20m",
    "token_max": "30m"
}
EOF
#"secret_id_ttl": "30m",
#"token_num_uses": "0",
#"secret_id_num_uses": "0",

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-role-$pkiName.json \
    $VAULT_ADDR/v1/auth/approle/role/pki_$pkiName-issuer-role

echo ""
echo "List approle / role"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/auth/approle/role/pki_$pkiName-issuer-role | jq

rm -f payload-role-$pkiName.json

echo ""
echo "Get ROLE_ID"
echo ""

export ROLE_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    $VAULT_ADDR/v1/auth/approle/role/pki_$pkiName-issuer-role/role-id | \
                    jq -r '.data.role_id' )

echo "ROLE_ID: $ROLE_ID"

echo ""
echo "Get SECRET_ID"
echo ""

export SECRET_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    --request POST \
                    $VAULT_ADDR/v1/auth/approle/role/pki_$pkiName-issuer-role/secret-id | \
                    jq -r '.data.secret_id' )
echo "SECRET_ID: $SECRET_ID"

export SECRET_ID64=$(echo $SECRET_ID | base64 )

echo "SECRET_ID64: $SECRET_ID64"

echo ""
echo "Testing appRole login"
echo ""

tee payload_login_$pkiName.json <<EOF
{
 "role_id": "${ROLE_ID}",
 "secret_id": "${SECRET_ID}"
}
EOF

curl -k --request POST --data @payload_login_$pkiName.json $VAULT_ADDR/v1/auth/approle/login | jq

rm -f payload_login_$pkiName.json


echo ""
echo "Create secret approle yaml file"
echo ""

mkdir -p "cert-manager-pki_$pkiName"
kubectl delete -f ./cert-manager-pki_$pkiName/cert-manager-secret-pki_$pkiName.yaml
rm -f ./cert-manager-pki_$pkiName/cert-manager-secret-pki_$pkiName.yaml
tee ./cert-manager-pki_$pkiName/cert-manager-secret-pki_$pkiName.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-pki-$pkiName
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-$pkiName
type: Opaque
stringData:
  SECRET_ID: ${SECRET_ID}
  SECRET_ID64: ${SECRET_ID64}
EOF

kubectl apply -f cert-manager-pki_$pkiName/cert-manager-secret-pki_$pkiName.yaml

echo ""
echo "Create vault issuer yaml file"
echo ""

kubectl delete -f ./cert-manager-pki_$pkiName/cert-manager-pki_$pkiName-ClusterIssuer.yaml
rm -f ./cert-manager-pki_$pkiName/cert-manager-pki_$pkiName-ClusterIssuer.yaml

CABUNDLE=$(cat ./certs/subca-$pkiName/bundle64.pem)
tee ./cert-manager-pki_$pkiName/cert-manager-pki_$pkiName-ClusterIssuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-pki-$pkiName-clusterissuer
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-$pkiName
spec:
  vault:
    path: pki_$pkiName/sign/pki_$pkiName-role
    server: https://vault-service
    caBundle: $CABUNDLE
    auth:
      appRole:
        path: approle
        roleId: ${ROLE_ID}
        secretRef:
          name: cert-manager-pki-$pkiName
          key: SECRET_ID
EOF

kubectl apply -f ./cert-manager-pki_$pkiName/cert-manager-pki_$pkiName-ClusterIssuer.yaml

echo ""
echo "Get ClusterIssuer list"
echo ""

sleep 2

kubectl get ClusterIssuer -n vault-ns -o wide

}

createVaultClusterIssuer $VAULT_TOKEN $VAULT_ADDR "cluster"

createVaultClusterIssuer $VAULT_TOKEN $VAULT_ADDR "edge"
