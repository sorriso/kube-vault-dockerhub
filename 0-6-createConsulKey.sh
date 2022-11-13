#!/bin/bash

cd certs

./_tools/consul keygen > ./GOSSIP_ENCRYPTION_KEY.txt

cd ..
