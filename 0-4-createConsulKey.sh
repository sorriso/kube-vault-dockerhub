#!/bin/bash

cd certs

./consul keygen > GOSSIP_ENCRYPTION_KEY.txt

cd ..
