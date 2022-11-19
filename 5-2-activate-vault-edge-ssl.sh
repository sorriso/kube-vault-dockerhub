#!/bin/bash


kubectl apply -f vault-ssl-edge/vault-consul-nginx-certificate.yaml

kubectl apply -f vault-ssl-edge/vault-nginx-certificate.yaml

sleep 3

kubectl apply -f vault-ssl-edge/vault-consul-nginx-deployment-ssl.yaml

kubectl apply -f vault-ssl-edge/vault-nginx-deployment-ssl.yaml

sleep 3

kubectl delete secret vault-nginx-secret-tls -n vault-ns

kubectl delete secret vault-secret-tls -n vault-ns
