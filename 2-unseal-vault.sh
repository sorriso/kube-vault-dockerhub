#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

FILE=./cluster-keys.json
if ! [ -f "$FILE" ];
then
    echo "initializing vault"
    kubectl exec vault-0 -- vault operator init  -format=json > ./cluster-keys.json
else
    echo "vault already initialized"
fi
echo "unsealing vault"
for idx in $(seq 1 3)
    do
        echo "index : $idx"
        VAULT_UNSEAL_KEY=$(cat ./cluster-keys.json | jq -r ".unseal_keys_b64[]" | sed -n "$idx"p )
        echo "unseal key : $VAULT_UNSEAL_KEY"
        kubectl exec vault-0 -- vault operator unseal "$VAULT_UNSEAL_KEY"
        sleep 3
    done
echo "status :"
kubectl exec vault-0 -- vault status -tls-skip-verify
