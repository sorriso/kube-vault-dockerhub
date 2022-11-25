#!/bin/bash


function createCA () {
folderName=$1

cd $folderName
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt

../_tools/cfssl gencert -initca ../_config/$folderName.json | ../_tools/cfssljson -bare $folderName
../_tools/cfssl sign -ca ../ca/ca.pem -ca-key ../ca/ca-key.pem -config ../_config/cfssl.json -profile subca $folderName.csr | ../_tools/cfssljson -bare $folderName
rm -f *.csr

cat $folderName.pem > bundle.pem
cat ../ca/ca.pem >> bundle.pem

KEY=$( sed '$!s/$/\\n/' ./$folderName-key.pem | tr -d '\n' )
PEM=$( sed '$!s/$/\\n/' ./$folderName.pem | tr -d '\n' )

tee payload-subcabundle.json <<EOF
{"pem_bundle": "$KEY\n$PEM"}
EOF

cd ..

}

echo ".        Creating subCA"


cd certs

cd subca-cert-consul
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt
cd ..


cd subca-cert-vault
rm -f *.key
rm -f *.pem
rm -f *.crt
rm -f *.csr
rm -f *.srl
rm -f *.txt
cd ..

createCA "subca-auth"

createCA "subca-cert"

createCA "subca-cluster"

createCA "subca-edge"

createCA "subca-nac"

cd ..
