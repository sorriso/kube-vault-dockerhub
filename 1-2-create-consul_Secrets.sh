#!/bin/bash

kubectl apply -f common
sleep 2

echo ".        Deleting consul secret (if any)"

kubectl delete secret consul -n vault-ns

echo ".        Creating consul secret"

kubectl create secret generic consul -n vault-ns \
--from-file="gossip-encryption-key=./certs/GOSSIP_ENCRYPTION_KEY.txt" \
--from-file="ca.pem=./certs/ca/ca.pem" \
--from-file="consul.pem=./certs/subca-cert-consul/bundle.pem" \
--from-file="consul-key.pem=./certs/subca-cert-consul/consul-key.pem"
