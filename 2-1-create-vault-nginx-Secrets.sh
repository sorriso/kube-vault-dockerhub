#!/bin/bash

kubectl apply -f common
sleep 2

echo ".        Deleting vault nginx secret (if any)"

kubectl delete secret vault-nginx-secret-tls -n vault-ns

echo ".        Creating vault nginx secret"

kubectl create secret generic vault-nginx-secret-tls -n vault-ns \
--from-file="SSL_CA_BUNDLE=./certs/ca/ca.pem" \
--from-file="SSL_CERT_BUNDLE=./certs/subca-vault/bundle.pem" \
--from-file="SSL_KEY=./certs/subca-vault/vault-key.pem"
