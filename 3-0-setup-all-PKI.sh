#!/bin/bash
echo ".    Running 3-1-setup-all-PKI.sh"

echo ".      Running 3-1-create-PKI-CA.sh"
./3-1-create-PKI-CA.sh

echo ".      Running 3-2-create-PKI-subCAs.sh"
./3-2-create-PKI-subCAs.sh
