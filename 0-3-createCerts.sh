#!/bin/bash

cd certs

#./_certsGen.sh "consul"
#./_certsGen.sh "vault"


# Generate SSL certificates for Consul
./cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=config/consul.json \
-profile=default \
config/ca.json | ./cfssljson -bare consul

cd ..
