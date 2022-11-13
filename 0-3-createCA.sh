#!/bin/bash

echo ".        Creating CA"

cd certs

cd subca
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl


cd ..
cd subca-consul
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl


cd ..
cd subca-vault
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

cd ..
cd ca
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

../_tools/cfssl gencert -initca ../_config/ca.json | ../_tools/cfssljson -bare ca
rm -f *.csr

cd ..
