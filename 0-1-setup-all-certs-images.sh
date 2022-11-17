#!/bin/bash
echo ".    Running 0-1-setup-all-certs.sh"

echo ".      Running 0-2-getSSLtools.sh"
./0-2-getSSLtools.sh

echo ".      Running 0-3-createCA.sh"
./0-3-createCA.sh

echo ".      Running 0-4-createSubCA_sec.sh"
./0-4-createSubCA_sec.sh

echo ".      Running 0-5-createCerts.sh"
./0-5-createCerts.sh

echo ".      Running 0-6-createConsulKey.sh"
./0-6-createConsulKey.sh

echo ".      Running 0-7-buildImages.sh"
./0-7-buildImages.sh
