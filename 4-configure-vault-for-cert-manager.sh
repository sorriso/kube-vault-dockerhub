#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | grep root_token | awk '{print $2}' | tr -d '"')
echo "VAULT_TOKEN : $VAULT_TOKEN"
echo ""

#export VAULT_ADDR=http://localhost:52100
#export VAULT_ADDR=http://localhost:8200
#export VAULT_ADDR=https://vault.kube.local
export VAULT_ADDR=http://vault.kube.local
echo "VAULT_ADDR : $VAULT_ADDR"
echo ""

# install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.9.1 \
  --set installCRDs=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4
echo ""


echo ""
echo "token"
echo ""

curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
#  --data '{"role_name": "pki_kube-role"}'\
  $VAULT_ADDR/v1/auth/token/create | jq > token.json

TOKEN=$(cat ./token.json | jq -r '.auth.client_token')
echo $TOKEN

rm issuer-kube-serviceaccount.yaml
echo ""

echo "Secret"
tee issuer-kube-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: issuer-kube-token
  namespace: vault-ns
  labels:
    app: vault
type: Opaque
stringData:
  token: $TOKEN
EOF

kubectl apply -f issuer-kube-secret.yaml

rm issuer-kube-secret.yaml
echo ""

echo "Issuer"
# Create a variable named ISSUER_SECRET_REF to capture the secret name
ISSUER_KUBE_SECRET_REF=$( kubectl get secrets -n cert-manager --output=json | jq -r '.items[].metadata | select(.name|startswith("issuer-kube-token")).name' )
echo "ISSUER_KUBE_SECRET_REF : $ISSUER_KUBE_SECRET_REF"
echo ""

cat > vault-issuer-kube.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: issuer-kube
  namespace: vault-ns
  labels:
    app: vault
spec:
  vault:
    server: $VAULT_ADDR
    path: pki/sign/pki_kube-role
    auth:
      tokenSecretRef:
        name: $ISSUER_KUBE_SECRET_REF
        key: token
EOF

kubectl apply -f vault-issuer-kube.yaml

rm vault-issuer-kube.yaml
echo ""

kubectl get issuers issuer-kube -n vault-ns -o wide
echo ""

echo "Certificate"
# to use it
#
cat > test-kube-local.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-kube-local-cert
  namespace: vault-ns
  labels:
    app: vault
spec:
  secretName: test-kube-local
  issuerRef:
    name: issuer-kube
  commonName: test1.kube.local
  dnsNames:
  - test1.kube.local
EOF

kubectl apply -f test-kube-local.yaml

rm -f test-kube-local.yaml
