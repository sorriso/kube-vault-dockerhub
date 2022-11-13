#!/bin/bash

kubectl apply -f common/vault-namespace.yaml
sleep 2

echo ".        Deleting consul nginx secret (if any)"

kubectl delete secret vault-consul-nginx-secret-tls -n vault-ns

echo ".        Creating consul nginx secret"

kubectl create secret generic vault-consul-nginx-secret-tls -n vault-ns \
--from-file="SSL_CA_BUNDLE=./certs/ca/ca.pem" \
--from-file="SSL_CERT_BUNDLE=./certs/subca-consul/bundle.pem" \
--from-file="SSL_KEY=./certs/subca-consul/consul-key.pem"
