#!/bin/bash

kubectl apply -f common/vault-namespace.yaml
sleep 3
kubectl apply -f common
sleep 3
kubectl apply -f vault
