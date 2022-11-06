#!/bin/bash

kubectl create secret generic consul -n vault-ns \
--from-file="gossip-encryption-key=./certs/GOSSIP_ENCRYPTION_KEY.txt" \
--from-file="ca.pem=./certs/ca.pem" \
--from-file="consul.pem=./certs/consul.pem" \
--from-file="consul-key.pem=./certs/consul-key.pem"
