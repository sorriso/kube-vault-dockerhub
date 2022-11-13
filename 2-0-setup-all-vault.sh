#!/bin/bash

echo ".    Running 2-0-setup-all-vault.sh"

rm -f cluster-keys.json

echo ".      Running 2-1-create-vault-nginx-Secrets.sh"
./2-1-create-vault-nginx-Secrets.sh

echo ".      Running 2-1-create-vault-nginx-Secrets.sh"
./2-2-create-vault-Secrets.sh

echo ".      Running 2-2-start-vault.sh"
./2-3-start-vault.sh

echo ".      Running 2-3-unseal-vault.sh"
./2-4-unseal-vault.sh
