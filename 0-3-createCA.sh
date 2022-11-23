#!/bin/bash

echo ".        Creating CA"

cd certs


cd subca-auth
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt

cd ..
cd subca-cert
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl


cd ..
cd subca-cert-consul
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl


cd ..
cd subca-cert-vault
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl


cd ..
cd subca-cluster
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt


cd ..
cd subca-edge
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt


cd ..
cd subca-frontoffice
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt


cd ..
cd subca-nac
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt


cd ..
cd ca
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

../_tools/cfssl gencert -initca ../_config/ca.json | ../_tools/cfssljson -bare ca
rm -f *.csr

KEY=$( sed '$!s/$/\\n/' ./ca-key.pem | tr -d '\n' )
PEM=$( sed '$!s/$/\\n/' ./ca.pem | tr -d '\n' )

tee payload-cabundle.json <<EOF
{"pem_bundle": "$KEY\n$PEM"}
EOF

cd ..
