How to deploy:

first run provision on all nodes in inventory:
 ```bash
    ansible-playbook -i inventory/inventory_vmware_workstation_local_lab.ini preinstall.yml --tags provision -kK --ask-vault-pass
```

Then create venv in this repo and install requirements:
```bash
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
```

then clone kubespray repo and checkout to desirable version also install requirements needed for python/ansible inside this venv: 
```bash
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    git checkout release-2.25
    git checkout tags/v2.25.1
    pip install -r requirements.txt
```

Then c/p our own variables into kubespray/inventory folder and use it instead of theirs, for example kube-vip,metallb, ingress-nginx, metrics-server..
Be careful that we are 1:1 with all default variables for that kubespray version!
```bash
    pwd/root/git_folders/kubespray/kubespray
    cp -ra ../clients/tino-prod/ inventory/
```

Install k8s with kubespray:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini cluster.yml --become --become-user=root
```

remove kubespray repo from our repo - we don't use their files in our repo.
Only when needed for install/modify/upgrade kubespray then clone it back into repo and always delete after finishing!
```bash
    rm -rf kubespray/
```

Manually add kubernetes config into management vm
Then when we have access to k8s - install additonal custom_roles after kubespray installation:
```bash
    scp -r [first-master-node-ip]:/etc/kubernetes/admin.conf /root/.kube/config
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags k8s_afterchanges --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_argocd --ask-vault-pass
```


How it all connects together -  External IaC for clients based on Kubespray:

![alt text](./tino-external-iac.jpeg?raw=true "Cratis Kubernetes Enviroment")

