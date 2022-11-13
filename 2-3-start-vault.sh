#!/bin/bash
echo ".        Starting vault"

kubectl apply -f common/vault-namespace.yaml
sleep 2
kubectl apply -f common
sleep 2
kubectl apply -f vault
sleep 10

PODNAME="vault"

PODS=$(kubectl -n vault-ns get pods -o=name | grep $PODNAME | grep -v "nginx" | sed "s/^.\{4\}//" )
array=(`echo $PODS | sed 's/,/\n/g'`)
for POD in "${array[@]}"; do
  echo ".          ****"
  echo ".          === waiting for pod : $POD ==="
  while true; do
    STATUS=$(kubectl get pod -n vault-ns $POD -o=json | jq '.status.containerStatuses[].ready' | sed 's/\"//g' )
    if [ "$STATUS" == "true" ]; then
      echo ".            $POD is Ready"
      break;
    else
      echo ".            $POD ready status is : $STATUS";
      sleep 5;
    fi
  done
done
echo ".          ********"

PODS=$(kubectl -n vault-ns get pods -o=name | grep $PODNAME | grep "nginx" | sed "s/^.\{4\}//" )
array=(`echo $PODS | sed 's/,/\n/g'`)
for POD in "${array[@]}"; do
  echo "****"
  echo "          === waiting for service : $POD ==="
  while true; do
    STATUS=$(kubectl get pod -n vault-ns $POD -o=json | jq '.status.containerStatuses[].ready' | sed 's/\"//g' )
    if [ "$STATUS" == "true" ]; then
      echo ".            $POD is Ready"
      break;
    else
      echo ".            $POD ready status is : $STATUS";
      sleep 5;
    fi
  done
done
echo ".          ****"
echo ".          ****"
