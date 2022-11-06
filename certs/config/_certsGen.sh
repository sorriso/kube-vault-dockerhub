#!/bin/bash

if [[ -z $1 ]];
then
    echo "No parameter passed."
    exit 0
else
    echo "Parameter passed = $1"
fi

export CERT_NAME=$1

echo "creating certs for $CERT_NAME"

echo ".  creating key & csr"

openssl req -out $CERT_NAME.csr -newkey rsa:2048 -nodes -keyout $CERT_NAME.key -config _san-$CERT_NAME.cnf

echo ".  creating cert & signing it with CA"

openssl x509 -req -in $CERT_NAME.csr -extfile ./_san-$CERT_NAME.cnf -extensions req_ext -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -sha256 -out $CERT_NAME.pem

rm -f *.csr
