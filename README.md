## Prerequisites

- at least 4 virtual machines with latest Ubuntu, tested on version 24.04

## Ansible-vault password
vault password for ansible is : password

## Quick Start
Clone this repo, go to desired kubespray version - with branches we follow branches, ie. tags of kubespray so for example to install kubernetes version 1.29.10 we would go inside  branch which has variables for that specific version:
```bash
    git clone https://github.com/tinhutins/kubespray.git
    cd kubespray
    git checkout v2.25.1
```

create venv inside this repo and source into it:
```bash
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
```

Then clone kubespray repo, checkout to that desired k8s version also here and install requirements needed for python/ansible inside this venv: 
```bash
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    git checkout release-2.25
    git checkout tags/v2.25.1
    pip install -r requirements.txt
    ansible --version
```

Run provision on all nodes in inventory, to setup hostname - timezone, etc:

 ```bash
    cd ../
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/preinstall.yml --tags provision -kK --ask-vault-pass
```

After that c/p our own variables into kubespray/inventory folder and use them instead, for example we add kube-vip, metallb, ingress-nginx, metrics-server...

```bash
    cd ~/git_folders/kubespray/kubespray/
    cp -ra ../clients/tino-prod/ inventory/
```

Be careful that we are 1:1 with all default variables for desired kubespray version (use win merge or something and check double changes) - then remove their local and sample inventories and variables when we have our own setup:
```bash
    rm -rf inventory/local inventory/sample
```

Install k8s with kubespray with our own inventory and variables - installation process takes about ~20minutes on normal network:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini cluster.yml --become --become-user=root --ask-vault-pass
```

remove kubespray repo from our base kubespray repo when done - we don't use their files in our repo so it's more clean.
Only when needed for install/modify/upgrade kubespray then clone it back into repo and always delete after finishing!
```bash
    cd ../
    rm -rf kubespray/
```

Manually add kubernetes config into ansible management vm (from which we also ran kubespray installation and has access to all machines and networks, and check if it works:

```bash
    scp -r [first-master-node-ip]:/etc/kubernetes/admin.conf /root/.kube/config
    kubectl get nodes
```

When we have access to k8s - install additional custom_roles after kubespray installation:
```bash
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags k8s_afterchanges --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_argocd --ask-vault-pass
```

Deactivate and remove venv from our repo at the end since we don't need ansible anymore:
```bash
    deactivate
    rm -rf venv-kubespray/
```

## Upgrade cluster
Procedure is almost the same as installing - clone kubespray repo get into new version tag and use our own inventory and variables while matching their template:
```bash
    git clone https://github.com/tinhutins/kubespray.git
    cd kubespray
    git checkout v2.26.0
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    git checkout release-2.26
    git checkout tags/v2.26.0
    pip install -r requirements.txt
    ansible --version
    cp -ra ../clients/tino-prod/ inventory/
    rm -rf inventory/local inventory/sample
    ansible-playbook -i inventory/tino-prod/inventory.ini -b upgrade-cluster.yml --ask-vault-pass
```

## Add nodes into cluster
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini scale.yml --limit="k8s-worker-2"  --ask-vault-pass
```

## Remove nodes from cluster
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini remove-node.yml -e node="k8s-worker-2"--ask-vault-pass
```

Idea is to have this kind of env at the and with all services around kubespray:

![alt text](./tino-external-iac.jpeg?raw=true "Tino - Kubernetes Enviroment")
