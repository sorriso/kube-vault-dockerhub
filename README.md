you like this work ?

[!["You like it ?"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/sorriso)

# kube-vault-dockerhub

Kubernetes yaml configuration files for vault using docker hub image

## prerequisite:

- Rancher desktop (or equivalent) installed locally & running with "containerd" selected as main command tool

## How to make it working :

- run "./1-start.sh" to start service

- run "./2-unseal-vault.sh" to init and unlock the vault (to be done at each (re)start)

- run "./3-create-pki.sh" to create a CA and 2 sub CA as example

- run "./1-stop.sh" to stop service
