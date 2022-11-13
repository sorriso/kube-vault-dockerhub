#!/bin/bash

echo ".        Get tools"

cd certs/_tools


if [ ! -f ./consul ]; then
    echo ".          downloading consul"
    curl -o consul.zip "https://releases.hashicorp.com/consul/1.13.3/consul_1.13.3_darwin_amd64.zip"
    unzip consul.zip
    rm -f consul.zip
    chmod +x ./consul
else
    echo ".            consul already available"
fi

if [ ! -f ./cfssl ]; then
    echo ".          downloading cfssl"
    curl -k -L -s "https://github.com/cloudflare/cfssl/releases/download/v1.6.3/cfssl_1.6.3_darwin_amd64" > cfssl
    chmod +x ./cfssl
else
    echo ".            cfssl already available"
fi

    if [ ! -f ./cfssljson ]; then
    echo ".          downloading cfssljson"
    curl -k -L -s "https://github.com/cloudflare/cfssl/releases/download/v1.6.3/cfssljson_1.6.3_darwin_amd64" > cfssljson
    chmod +x ./cfssljson
else
    echo ".            cfssljson already available"
fi

cd ../..
