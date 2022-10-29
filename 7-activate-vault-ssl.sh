#!/bin/bash

rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
rm -f ./*.csr

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./Initial_root_token.txt)

export VAULT_ADDR=http://vault.kube.local

kubectl delete -f vault/vault-secret.yaml

kubectl apply -f vault-ssl/Certificate-kube-vault.yaml

kubectl apply -f vault-ssl/vault-nginx-ssl-secret.yaml

kubectl apply -f vault-ssl/vault-ssl-deployment.yaml
