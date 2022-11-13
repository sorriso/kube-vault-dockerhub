#!/bin/bash

echo ".        Creating certs subCA consul"

cd certs


cd subca-consul
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

../_tools/cfssl gencert \
-ca=../subca/subca.pem \
-ca-key=../subca/subca-key.pem \
-config=../_config/cfssl.json \
-profile=consul \
../_config/subca-consul.json | ../_tools/cfssljson -bare consul
rm -f *.csr
cat consul.pem > bundle.pem
cat ../subca/subca.pem >> bundle.pem

echo ".        Creating certs subCA vault"

cd ..
cd subca-vault
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl

../_tools/cfssl gencert \
-ca=../subca/subca.pem \
-ca-key=../subca/subca-key.pem \
-config=../_config/cfssl.json \
-profile=vault \
../_config/subca-vault.json | ../_tools/cfssljson -bare vault
rm -f *.csr

cat vault.pem > bundle.pem
cat ../subca/subca.pem >> bundle.pem

cd ..
