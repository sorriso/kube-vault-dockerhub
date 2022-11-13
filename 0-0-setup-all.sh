#!/bin/bash
echo "Running 0-0-setup-all.sh"

echo ".  Running 0-1-setup-all-certs-images.sh"
./0-1-setup-all-certs-images.sh

echo ".  Running 1-0-setup-all-consul.sh"
./1-0-setup-all-consul.sh

echo ".  Running 2-0-setup-all-vault.sh"
./2-0-setup-all-vault.sh

echo ".  Running 3-0-setup-all-PKI.sh"
./3-0-setup-all-PKI.sh

echo ".  Running 4-0-setup-all-cert-manager.sh"
./4-0-setup-all-cert-manager.sh
