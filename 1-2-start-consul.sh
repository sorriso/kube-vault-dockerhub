#!/bin/bash

kubectl apply -f common/vault-namespace.yaml
sleep 3
kubectl apply -f consul

#kubectl --namespace vault-ns logs consul-0
