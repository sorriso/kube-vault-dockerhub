# you like this work ?

[!["You like it ?"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/sorriso)

# kube-vault-dockerhub

Kubernetes yaml configuration files for vault (and cert-manager) using docker hub image

> DISCLAMER : This stuff is just for helping people to understand how things work, it is NOT for production use, I do NOT provide any support on it

## prerequisite:

1. Rancher desktop (tested on V1.6.1) installed locally & running (tested on OSX 12.6) with:

   - "containerd" selected as main command tool

   - the "traefik" installed by default desactivated

   - kubernetes v1.4.27 selected / installed

2. Volume manager (longhorn) installed & working well:

   - See [kube-gitops-longhorn](https://github.com/sorriso/kube-gitops-longhorn) to install it.

3. Ingress (treafik) installed & working well:

   - See [kube-traefik-ingress-controller](https://github.com/sorriso/kube-traefik-ingress-controller) to install it.

4. File /etc/hosts updated with:

  - 127.0.0.1 vault.kube.local

## How to make it working :

1. run "./1-start-vault.sh" to install & start vault

2. open http://vault.kube.local in your web browser,
  - init the vault (set values to "Key shares = 1" and "Key threshold = 1" and press init button ),
  - store "unseal value" in "unseal_key_1.txt" and "root token value" in "Initial_root_token.txt",
  - click on "continue" and use these values to unseal & login

3. run :
  - "./3-create-PKI-CA.sh" to create a CA
  - "./4-create-PKI-subCA-kube.sh" to create a subCA dedicated to cluster frontend (like vault.kube.local)
  - "./5-create-PKI-subCA-cluster.sh" to create a subCA dedicated to internal pod's cluster (for mTLS between pods by example)
  - At the end of each scripts above, in case of successful installation, you should see certificates data to be displayed

4. run :
  - "./6-1-configure-vault-for-cert-manager-installation.sh" to install cert manager
  - "./6-2-configure-vault-for-cert-manager-kube-issuer.sh" to install a certificat issuer for "kube" (like *.kube.local)
  - "./6-3-configure-vault-for-cert-manager-cluster-issuer.sh" to install a certificat issuer for "cluster" (like <pod>.<namespace>.svc.cluster.local)
  - "./6-4-configure-vault-for-cert-manager-test.sh" to test if its working fine

5. run :
   - "./7-activate-vault-ssl.sh" to update vault configuration in order to use itself

6. run :
   - "./8-stop-vault.sh" to stop vault service (but volume/data are kept/not destroyed)
