#!/bin/bash

cd certs

echo ".        Creating GOSSIP"

./_tools/consul keygen > ./GOSSIP_ENCRYPTION_KEY.txt

cd ..
