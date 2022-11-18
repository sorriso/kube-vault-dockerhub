#!/bin/bash
echo ".    Running 3-1-setup-all-PKI.sh"

echo ".      Running 3-1-create-PKI-CA.sh"
./3-1-create-PKI-CA.sh

echo ".      Running 3-2-create-PKI-subCA-edge.sh"
./3-2-create-PKI-subCA-edge.sh

echo ".      Running 3-3-create-PKI-subCA-cluster.sh"
./3-3-create-PKI-subCA-cluster.sh

echo ".      Running 3-4-create-PKI-subCA-nac.sh"
./3-4-create-PKI-subCA-nac.sh

echo ".      Running 3-5-create-PKI-subCA-frontoffice.sh"
./3-5-create-PKI-subCA-frontoffice.sh

echo ".      Running 3-5-create-PKI-subCA-sec.sh"
./3-6-create-PKI-subCA-sec.sh
