#!/bin/bash

echo ""
echo "Testing cert only generation"
echo ""

kubectl apply -f cert-test-kube
#kubectl delete -f cert-test-kube

echo ""
echo "Testing cert for od generation"
echo ""

kubectl apply -f cert-test-cluster
#kubectl delete -f cert-test-cluster
