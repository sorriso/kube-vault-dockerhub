nerdctl -n k8s.io pull hashicorp/vault:1.9.7
rm -f ./payload*.json
rm -f ./*.pem
rm -f ./*.crt
kubectl apply -f vault
