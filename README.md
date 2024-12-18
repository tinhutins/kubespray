# Kubespray Kubernetes Ecosystem Automation with Ansible

This project automates the creation of a complete Kubernetes ecosystem using Kubespray and Ansible. It includes setting up a High Availability (HA) Kubernetes cluster with essential services and tools for managing and deploying applications.

## Prerequisites

- At least 4 virtual machines running Ubuntu 24.04.
- Ansible Vault password: `password`.
- Optional - Self-Signed Certificates: Generate wildcard self-signed certificates for a test domain using the provided script (ssl.sh).

## Features

- **Kubernetes HA Cluster**: Provisioned using Kubespray.
- **MetalLB**: Provides load balancing for services.
- **Ingress-NGINX**: Manages HTTP and HTTPS traffic.
- **Persistent Storage**: Longhorn is used for storage solutions.

## Quick Start
1. Clone this repo, checkout to a specific Kubernetes version, with branches we follow branches, ie. tags of kubespray:
```bash
    git clone https://github.com/tinhutins/kubespray.git
    cd kubespray
    git checkout v2.25.1 # Example for Kubernetes v1.29.10
```

2. Create and activate a Python virtual environment:
```bash
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
```

3. Clone the official Kubespray repo, check out the version tag, and install dependencies:
```bash
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    git checkout release-2.25
    git checkout tags/v2.25.1
    pip install -r requirements.txt
    ansible --version
```

4. Run the provision playbook to set up hostnames, timezones, and other system configurations on desired nodes:

 ```bash
    cd ../
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/preinstall.yml --tags provision -kK --ask-vault-pass
```

5. Copy your custom variables into the Kubespray inventory directory:

```bash
    cd ~/git_folders/kubespray/kubespray/
    cp -ra ../clients/tino-prod/ inventory/
```

6. Ensure the variables match the Kubespray version you're using (check for duplicate or conflicting changes). After that remove the sample and local inventory files:
```bash
    rm -rf inventory/local inventory/sample
```

7. Install Kubernetes using your custom inventory and variables. Installation process takes about ~25minutes on normal network:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini cluster.yml --become --become-user=root --ask-vault-pass
```

8. Clean Up - Once installation is complete, remove the Kubespray repo from your base setup. Only when needed for example to modify or upgrade kubespray then clone it back into our repo and always delete after finishing!
```bash
    cd ../
    rm -rf kubespray/
```

9. Access Kubernetes - Copy the Kubernetes config from the first master node to your management VM:

```bash
    scp -r [first-master-node-ip]:/etc/kubernetes/admin.conf /root/.kube/config
    kubectl get nodes
```

10. Post-Install Configuration - After Kubernetes is up and running, install additional custom roles (like ArgoCD):
```bash
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags k8s_afterchanges --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_argocd --ask-vault-pass
```

11. Clean Up Virtual Environment - Once done, deactivate and remove the virtual environment:
```bash
    deactivate
    rm -rf venv-kubespray/
```

## Upgrade cluster
Upgrading the cluster follows a similar process to installation. Just update to a newer version of Kubespray - Upgrade process takes about ~30minutes on normal network:
```bash
    git clone https://github.com/tinhutins/kubespray.git
    cd kubespray
    git checkout v2.26.0 # Example for new Kubernetes version
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
    deactivate
    cd ..
    rm -rf kubespray venv-kubespray
```

## Add nodes into cluster
To add a new node to the cluster:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini scale.yml --limit="k8s-worker-2"  --ask-vault-pass
```

## Remove nodes from cluster
To remove a node from the cluster:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini remove-node.yml -e node="k8s-worker-2"--ask-vault-pass
```

Idea is to have this kind of env at the and with all services around kubespray:

![alt text](./tino-external-iac.jpeg?raw=true "Tino - Kubernetes Enviroment")