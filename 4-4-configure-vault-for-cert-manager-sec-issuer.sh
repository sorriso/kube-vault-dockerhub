#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local

echo "*****************************************************************************************************************************************"
echo "Configuration pki_sec-issuer"
echo ""

kubectl delete -f cert-manager-pki_sec

echo ""
echo "Create dedicated policy"
echo ""

tee payload-issuer-sec.json <<EOF
{
  "policy": "path \"pki_sec/*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"] }"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-issuer-sec.json \
    $VAULT_ADDR/v1/sys/policy/pki_sec-issuer-policy

rm -f payload-issuer-sec.json

echo ""
echo "List policy"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/sys/policy/pki_sec-issuer-policy | jq

echo ""
echo "Create role"
echo ""

tee payload-role-sec.json <<EOF
{
    "policies": "pki_sec-issuer-policy",
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
    --data @payload-role-sec.json \
    $VAULT_ADDR/v1/auth/approle/role/pki_sec-issuer-role

echo ""
echo "List approle / role"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/auth/approle/role/pki_sec-issuer-role | jq

rm -f payload-role-sec.json

echo ""
echo "Get ROLE_ID"
echo ""

export ROLE_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    $VAULT_ADDR/v1/auth/approle/role/pki_sec-issuer-role/role-id | \
                    jq -r '.data.role_id' )

echo "ROLE_ID: $ROLE_ID"

echo ""
echo "Get SECRET_ID"
echo ""

export SECRET_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    --request POST \
                    $VAULT_ADDR/v1/auth/approle/role/pki_sec-issuer-role/secret-id | \
                    jq -r '.data.secret_id' )
echo "SECRET_ID: $SECRET_ID"

export SECRET_ID64=$(echo $SECRET_ID | base64 )

echo "SECRET_ID64: $SECRET_ID64"

echo ""
echo "Testing appRole login"
echo ""

tee payload_login_edge.json <<EOF
{
 "role_id": "${ROLE_ID}",
 "secret_id": "${SECRET_ID}"
}
EOF

curl -k --request POST --data @payload_login_edge.json $VAULT_ADDR/v1/auth/approle/login \
    | jq

rm -f payload_login_edge.json

echo ""
echo "Create secret approle yaml file"
echo ""

rm -f cert-manager-pki_sec/cert-manager-secret-approle-pki_sec.yaml
tee cert-manager-pki_sec/cert-manager-secret-approle-pki_sec.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-pki-sec
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-edge
type: Opaque
stringData:
  SECRET_ID: ${SECRET_ID}
  SECRET_ID64: ${SECRET_ID64}
EOF

kubectl apply -f cert-manager-pki_sec/cert-manager-secret-approle-pki_sec.yaml

echo ""
echo "Create vault issuer yaml file"
echo ""

rm -f cert-manager-pki_sec/cert-manager-pki_sec-ClusterIssuer.yaml

CABUNDLE=$(cat ./certs/subca/bundle64.pem)
tee cert-manager-pki_sec/cert-manager-pki_sec-ClusterIssuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-pki-sec-issuer
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-edge
spec:
  vault:
    path: pki_sec/sign/pki_sec-role
    server: https://vault-service
    caBundle: $CABUNDLE
    auth:
      appRole:
        path: approle
        roleId: ${ROLE_ID}
        secretRef:
          name: cert-manager-pki-sec
          key: SECRET_ID
EOF

kubectl apply -f cert-manager-pki_sec/cert-manager-pki_sec-ClusterIssuer.yaml

echo ""
echo "Get issuer list"
echo ""

sleep 5

kubectl get ClusterIssuer -n vault-ns -o wide
