## Prerequisites

- at least 4 virtual machines with Ubuntu 24.04 system

## Ansible-vault password
vault password for ansible is : password

## Quick Start
Create venv inside this repo and source into it:
```bash
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
```

Then clone kubespray repo, checkout to desired k8s version and install requirements needed for python/ansible inside this venv: 
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

Manually add kubernetes config into ansible management vm (from which we also ran kubespray installation and has access to all machines and networks):

```bash
    scp -r [first-master-node-ip]:/etc/kubernetes/admin.conf /root/.kube/config
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

![alt text](./tino-external-iac.jpeg?raw=true "Cratis Kubernetes Enviroment")