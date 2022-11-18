#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )

export VAULT_ADDR=https://vault.kube.local


# install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace vault-ns \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4

helm upgrade -i -n vault-ns cert-manager-csi-driver jetstack/cert-manager-csi-driver --wait

echo ""
echo "Enable approle"
echo ""

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    $VAULT_ADDR/v1/sys/auth/approle

sleep 5
