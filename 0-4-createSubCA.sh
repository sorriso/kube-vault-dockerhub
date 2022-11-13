#!/bin/bash

echo ".        Creating subCA"

cd certs


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
cd subca
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

../_tools/cfssl gencert -initca ../_config/subca.json | ../_tools/cfssljson -bare subca
../_tools/cfssl sign -ca ../ca/ca.pem -ca-key ../ca/ca-key.pem -config ../_config/cfssl.json -profile subca subca.csr | ../_tools/cfssljson -bare subca
rm -f *.csr

cd ..

# openssl rsa -in intermediate.key.pem -out intermediate.key.pem -outform pem
# cat intermediate.cert.pem intermediate.key.pem ca.cert.pem > bundle.pem
# vault write intca/config/ca pem_bundle=@bundle.pem
