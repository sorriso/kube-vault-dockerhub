#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

export VAULT_TOKEN=$(cat ./Initial_root_token.txt)

export VAULT_ADDR=http://vault.kube.local



kubectl delete -f vault/vault-secret.yaml

kubectl apply -f vault-ssl/Certificate-kube-vault.yaml

kubectl apply -f vault-ssl/vault-nginx-ssl-secret.yaml

kubectl delete -f vault/vault-nginx-deployment.yaml
kubectl apply -f vault-ssl/vault-nginx-ssl-deployment.yaml
kubectl delete -f vault/vault-secret.yaml

kubectl apply -f vault-ssl/vault-ssl-deployment.yaml
