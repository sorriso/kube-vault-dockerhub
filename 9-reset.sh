#!/bin/bash

cd volume/data

rm -Rf *

cd ../home

rm -Rf *

cd ../..

cp template/vault-deployment-init.yaml vault/vault-deployment.yaml

cp template/vault-secret-init.yaml vault/vault-secret.yaml

cp template/vault-configmap-init.yaml vault/vault-configmap.yaml

rm -f *.json
