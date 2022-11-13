#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local

echo "*****************************************************************************************************************************************"
echo "Configuration pki_edge-issuer"
echo ""

kubectl delete -f cert-manager-pki_edge

echo ""
echo "Create dedicated policy"
echo ""

tee payload-issuer-edge.json <<EOF
{
  "policy": "path \"pki_edge/*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"] }"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-issuer-edge.json \
    $VAULT_ADDR/v1/sys/policy/pki_edge-issuer-policy

rm -f payload-issuer-edge.json

echo ""
echo "List policy"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/sys/policy/pki_edge-issuer-policy | jq

echo ""
echo "Create role"
echo ""

tee payload-role-edge.json <<EOF
{
    "policies": "pki_edge-issuer-policy",
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
    --data @payload-role-edge.json \
    $VAULT_ADDR/v1/auth/approle/role/pki_edge-issuer-role

echo ""
echo "List approle / role"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request GET \
    $VAULT_ADDR/v1/auth/approle/role/pki_edge-issuer-role | jq

rm -f payload-role-edge.json

echo ""
echo "Get ROLE_ID"
echo ""

export ROLE_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    $VAULT_ADDR/v1/auth/approle/role/pki_edge-issuer-role/role-id | \
                    jq -r '.data.role_id' )

echo "ROLE_ID: $ROLE_ID"

echo ""
echo "Get SECRET_ID"
echo ""

export SECRET_ID=$(curl -k \
                    --silent \
                    --header "X-Vault-Token: $VAULT_TOKEN" \
                    --request POST \
                    $VAULT_ADDR/v1/auth/approle/role/pki_edge-issuer-role/secret-id | \
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

rm -f cert-manager-pki_edge/cert-manager-secret-approle-pki_edge.yaml
tee cert-manager-pki_edge/cert-manager-secret-approle-pki_edge.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-pki-edge
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-edge
type: Opaque
stringData:
  SECRET_ID: ${SECRET_ID}
  SECRET_ID64: ${SECRET_ID64}
EOF

kubectl apply -f cert-manager-pki_edge/cert-manager-secret-approle-pki_edge.yaml

echo ""
echo "Create vault issuer yaml file"
echo ""

rm -f cert-manager-pki_edge/cert-manager-pki_edge-ClusterIssuer.yaml
tee cert-manager-pki_edge/cert-manager-pki_edge-ClusterIssuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-pki-edge-clusterissuer
  namespace: vault-ns
  labels:
    app: cert-manager
    layer: pki-edge
spec:
  vault:
    path: pki_edge/sign/pki_edge-role
    server: https://vault-service
    #server: vault.kube.local
    #caBundle: <base64 encoded caBundle PEM file>
    auth:
      appRole:
        path: approle
        roleId: ${ROLE_ID}
        secretRef:
          name: cert-manager-pki-edge
          key: SECRET_ID
EOF

kubectl apply -f cert-manager-pki_edge/cert-manager-pki_edge-ClusterIssuer.yaml

echo ""
echo "Get issuer list"
echo ""

sleep 5

kubectl get ClusterIssuer -n vault-ns -o wide
