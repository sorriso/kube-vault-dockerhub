#!/bin/bash

cd builds

cd consul

./0-build-image.sh

cd ..

cd nginx

./0-build-image.sh

cd ..

cd vault

./0-build-image.sh

cd ..

cd ..
