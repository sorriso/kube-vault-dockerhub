#!/bin/bash

cd builds

cd consul-alpine

./0-build-image.sh

cd ..
cd consul-quai

./0-build-image.sh

cd ..
cd consul-ubi8

./0-build-image.sh

cd ..
cd nginx

./0-build-image.sh

cd ..
cd vault-quai

./0-build-image.sh

#cd ..
#cd vault-alpine

#./0-build-image.sh

#cd ..
#cd vault-ubi8

#./0-build-image.sh
cd ..

cd ..
