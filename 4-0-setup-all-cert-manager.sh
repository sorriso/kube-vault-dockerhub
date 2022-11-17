#!/bin/bash

echo ".    Running 3-1-setup-all-cert-manager.sh"

echo ".      Running 4-1-configure-vault-for-cert-manager-installation.sh"
./4-1-configure-vault-for-cert-manager-installation.sh

echo ".      Running 4-2-configure-vault-for-cert-manager-kube-issuer.sh"
./4-2-configure-vault-for-cert-manager-kube-issuer.sh

echo ".      Running 4-3-configure-vault-for-cert-manager-edge-issuer.sh"
./4-3-configure-vault-for-cert-manager-edge-issuer.sh

echo ".      Running 4-4-configure-vault-for-cert-manager-sec-issuer.sh"
./4-4-configure-vault-for-cert-manager-sec-issuer.sh
