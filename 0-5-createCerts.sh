#!/bin/bash

function createCert () {
    certFolderName=$1
    subcaFolderName=$2
    certName=$3

    cd $certFolderName

    rm -f *.key
    rm -f *.pem
    rm -f *.crt
    rm -f *.csr
    rm -f *.srl
    rm -f *.txt

    ../_tools/cfssl gencert -ca=../$subcaFolderName/$subcaFolderName.pem -ca-key=../$subcaFolderName/$subcaFolderName-key.pem -config=../_config/cfssl.json -profile=$certName ../_config/$subcaFolderName-$certName.json | ../_tools/cfssljson -bare $certName
    rm -f *.csr
    cat $certName.pem > bundle.pem
    cat ../$subcaFolderName/$subcaFolderName.pem >> bundle.pem

    cd ..
}

cd certs

"echo .        Creating certs subCA consul"

createCert "subca-cert-consul" "subca-cert" "consul"

echo ".        Creating certs subCA vault"

createCert "subca-cert-vault" "subca-cert" "vault"

echo ".        Creating certs subCA Simple"

createCert "subca-cert-simple" "subca-cert" "simple"

cd ..

cd ..
