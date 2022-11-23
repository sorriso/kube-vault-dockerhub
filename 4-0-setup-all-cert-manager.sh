#!/bin/bash

echo ".    Running 3-1-setup-all-cert-manager.sh"

echo ".      Running 4-1-configure-vault-for-cert-manager-installation.sh"
./4-1-configure-vault-for-cert-manager-installation.sh

echo ".      Running 4-2-configure-vault-for-cert-manager-ClusterIssuers.sh"
./4-2-configure-vault-for-cert-manager-ClusterIssuers.sh

echo ".      Running 4-3-configure-vault-for-cert-manager-Issuers.sh"
./4-3-configure-vault-for-cert-manager-Issuers.sh
