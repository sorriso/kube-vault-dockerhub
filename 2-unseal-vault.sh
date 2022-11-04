#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

#export VAULT_TOKEN=$(cat ./cluster-keys.json | jq -r ".root_token" )
export VAULT_TOKEN=$(cat ./Initial_root_token.txt)
echo $VAULT_TOKEN
kubectl exec -n vault-ns vault-0 -- vault login $VAULT_TOKEN

#
# to tune kube cluster DNS as it is working locally
# go in "storage / configMap"
# edit YAML of "ConfigMap: coredns"
# insert the line below just after "ready"
#   rewrite name vault.kube.com vault-service.vault-ns.svc.cluster.local
# then go in "workload / pods" and delete "coredns-xxxx" pod in "Namespace: kube-system"

export VAULT_ADDR=https://vault.kube.local

FILE=./cluster-keys.json
if ! [ -f "$FILE" ];
then
    echo "initializing vault"
    kubectl exec -n vault-ns vault-0 -- vault operator init  -format=json > ./cluster-keys.json
else
    echo "vault already initialized"
fi

echo "unsealing vault"
echo ""
echo ""

for srv in $(seq 0 1)
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
