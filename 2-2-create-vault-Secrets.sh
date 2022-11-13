#!/bin/bash

kubectl apply -f common/vault-namespace.yaml
sleep 2

echo ".        Deleting vault secret (if any)"

kubectl delete secret vault-secret-tls -n vault-ns

echo ".        Creating vault secret"

kubectl create secret generic vault-secret-tls -n vault-ns \
--from-file="SSL_CA_BUNDLE=./certs/ca/ca.pem" \
--from-file="SSL_CERT_BUNDLE=./certs/subca-vault/bundle.pem" \
--from-file="SSL_KEY=./certs/subca-vault/vault-key.pem"
