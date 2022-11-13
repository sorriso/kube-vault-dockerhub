#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

FILE=./cluster-keys.json
if ! [ -f "$FILE" ];
then
    echo "initializing vault"
    kubectl exec --stdin=true --tty=true -n vault-ns vault-0 -- vault operator init -format=json > ./cluster-keys.json
else
    echo "vault already initialized"
fi

export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )
echo $VAULT_TOKEN
kubectl exec -n vault-ns vault-0 -- vault login $VAULT_TOKEN

echo "unsealing vault"
echo ""
echo ""

for srv in $(seq 0 2)
    do
    echo "unsealing server : vault-$srv"
    for idx in $(seq 1 3)
        do
            echo "unseal key index : $idx"
            VAULT_UNSEAL_KEY=$(cat ./cluster-keys.json | jq -r ".unseal_keys_b64[]" | sed -n "$idx"p )
            echo "unseal key : $VAULT_UNSEAL_KEY"

            kubectl exec -n vault-ns vault-$srv -- vault operator unseal "$VAULT_UNSEAL_KEY"

            sleep 2
        done
    echo ""
    echo ""
    done
echo ""
kubectl exec -n vault-ns vault-0 -- vault status -tls-skip-verify


# kubectl get pods
# kubectl -n vault-ns exec -it vault-0 -- /bin/sh
