#!/bin/bash

echo ".    Running 5-0-setup-all-ssl-internal.sh"

rm -f cluster-keys.json

echo ".      Running 5-1-activate-vault-edge-ssl.sh"
./5-1-activate-vault-edge-ssl.sh

echo ".      Running 5-2-activate-vault-cluster-ssl.sh"
./5-2-activate-vault-cluster-ssl.sh
h
