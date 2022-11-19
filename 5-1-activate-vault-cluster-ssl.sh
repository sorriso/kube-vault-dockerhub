#!/bin/bash

kubectl apply -f vault-ssl-cluster/vault-consul-statefulset-ssl.yaml

PODNAME="consul"

while true; do
    STATUS=$(kubectl get pod -n vault-ns $POD -o=json | jq '.status.containerStatuses[].ready' | sed 's/\"//g' )
    if [ "$STATUS" == "4" ]; then
      echo ".            $POD is Ready"
      break;
    else
      echo ".            $POD ready status is : $STATUS";
      sleep 5;
    fi
done


#kubectl apply -f vault-ssl-cluster/vault-statefulset-ssl.yaml
