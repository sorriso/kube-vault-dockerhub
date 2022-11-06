#!/bin/bash

cd certs

rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

# generate CSR and KEY file
#openssl req -out root-ca.csr -newkey rsa:2048 -nodes -keyout root-ca.key -config _san-CA.cnf

# Create a self-signed certificate from a SAN/UCC certificate request
#openssl x509 -req -in ./root-ca.csr -extfile ./_san-CA.cnf -extensions req_ext -signkey ./root-ca.key -out root-ca.pem

./cfssl gencert -initca config/ca.json | ./cfssljson -bare ca

cd ..
