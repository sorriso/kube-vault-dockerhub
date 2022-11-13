#!/bin/bash

echo ".    Running 1-0-setup-all-consul.sh"

echo ".      1-1-createConsulKey.sh"
./1-1-createConsulKey.sh

echo ".      1-2-create-consul_Secrets.sh"
./1-2-create-consul_Secrets.sh

echo ".      1-3-create-consul-nginx-Secrets.sh"
./1-3-create-consul-nginx-Secrets.sh

echo ".      1-4-start-consul.sh"
./1-4-start-consul.sh
