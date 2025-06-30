# Kubespray Kubernetes Ecosystem Automation with Ansible

This project automates the creation of a complete Kubernetes ecosystem using Kubespray and Ansible. 
It includes setting up a High Availability (HA) Kubernetes cluster with essential services and tools for managing and deploying applications.

---

## Prerequisites

- **Virtual Machines:** At least 4 VMs running Ubuntu 24.04 with the following minimum specs:
  - 2 CPUs
  - 2GB RAM
  - 20GB disk space
- **Ansible Vault Password:** `password`.
- Optional :
   - Self-Signed Certificates: Generate wildcard self-signed certificates for a test domain using the provided script (ssl.sh) located in branch gen-crt.
   - If you generated new certificate it is also important to add it into custom group_vars/custom_vars/ssl-vault.yml


---

## Features

- **Kubernetes HA Cluster**: Provisioned using Kubespray and kube-vip.
- **MetalLB**: Provides load balancing for services.
- **Ingress-NGINX**: Manages HTTP and HTTPS traffic.
- **Persistent Storage**: Longhorn is used for storage solutions.

---

## Additional notes 

- Always validate the compatibility of variables and customizations with the specific version of Kubespray you're using.
- For more details on Kubespray, refer to the Kubespray documentation [https://github.com/kubernetes-sigs/kubespray].
- Ensure regular backups before performing upgrades or scaling operations to avoid data loss.

---

## Quick Start
#### 1. Clone this repository 
Switch to the branch that corresponds to the desired Kubespray Kubernetes version. With branches we follow branches, ie. tags of kubespray official repo:
```bash
    git clone https://github.com/tinhutins/kubespray.git
    cd kubespray
    git checkout v2.25.1 # Example for Kubernetes v1.29.10
```

#### 2. Create and activate a Python virtual environment:
```bash
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
```

#### 3. Clone the Official Kubespray Repository and Install Dependencies
Clone the official Kubespray repo, check out the version tag, and install dependencies:
```bash
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    # Example: Checkout release and tag for Kubernetes v1.29.10
    git checkout release-2.25
    git checkout tags/v2.25.1
    pip install -r requirements.txt
    ansible --version
```

#### 4. Provision the Nodes
Run the pre-installation playbook to configure system settings like hostnames, timezones, and prerequisites on the target nodes:

 ```bash
    cd ../
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/preinstall.yml --tags provision -kK --ask-vault-pass
```

#### 5. Copy Custom Inventory Variables
Copy your custom inventory variables into the Kubespray inventory directory to ensure consistency:

```bash
    #cd into kubespray official repo and copy our inv variables inside their inventory folder
    cd ~/git_folders/kubespray/kubespray/
    cp -ra ../clients/tino-prod/ inventory/
```

#### 6. Setup Custom Inventory Variables
Ensure the variables values match the Kubespray version you're using (check for duplicate or conflicting changes). After that remove the sample and local inventory files:
```bash
    rm -rf inventory/local inventory/sample
```

#### 7. Install Kubernetes Cluster
Run the installation playbook to deploy Kubernetes using your custom inventory and variables. This process takes around 25 minutes under normal network conditions:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini cluster.yml --become --become-user=root --ask-vault-pass
```

#### 8. Access the Kubernetes Cluster
Copy the Kubernetes configuration file from the first master node to your management machine and verify the cluster status:

```bash
    scp -r [first-master-node-ip]:/etc/kubernetes/admin.conf /root/.kube/config
    kubectl get nodes
```

#### 9. Post-Install Configuration
Install additional tools and custom roles, such as Longhorn, monitoring stack and ArgoCD, to enhance the cluster functionality:
```bash
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags k8s_afterchanges --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_longhorn --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_argocd --ask-vault-pass
    ansible-playbook -i clients/tino-prod/inventory.ini ansible/postinstall.yml --tags install_k8s_prometheus_grafana_loki --ask-vault-pass
```

#### 10. Post-Installation Cleanup
Deactivate and remove the Python virtual environment also remove the official Kubespray repository after installation to maintain a clean setup.
```bash
    cd ../
    deactivate
    rm -rf kubespray/ venv-kubespray/
```

---

## Upgrade cluster
To upgrade the cluster, update the Kubespray repository to a newer version. The process takes approximately 30 minutes under normal network conditions.

## Prerequisites for upgrade
Create a new branch for this new version of kubernetes if it doesn't exists or just checkout to that branch if already defined:
```bash
    git checkout -b v2.27.0
    #if already created
    git checkout v2.27.0
```
Afterwards ensure all files are copied from k8s previous branch into this new one (using vscode cp or directly with linux cp).


#### Run following commands for upgrading k8s:

```bash
    git checkout v2.27.0 # if not already, checkout to new branch which has new Kubernetes version in our repo
    python3 -m venv venv-kubespray
    source venv-kubespray/bin/activate
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray 
    git checkout release-2.27 # checkout to new Kubernetes release in kubespray repo
    git checkout tags/v2.27.0 # checkout to new Kubernetes tag in kubespray repo
    pip install -r requirements.txt
    ansible --version
    #Setup Custom Inventory Variables - Ensure the variables values match the Kubespray version you're using (check for duplicate or conflicting changes). 
    cp -ra ../clients/tino-prod/ inventory/
    # After that remove the sample and local inventory files:
    rm -rf inventory/local inventory/sample
    ansible-playbook -i inventory/tino-prod/inventory.ini -b upgrade-cluster.yml --ask-vault-pass
    #Post-Upgrade Cleanup
    deactivate
    cd ..
    rm -rf kubespray/ venv-kubespray/
```
---

## Add nodes into the cluster
To add a new node to the cluster:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini scale.yml --limit="k8s-worker-2"  --ask-vault-pass
```

---

## Remove nodes from the cluster
To remove a node from the cluster:
```bash
    ansible-playbook -i inventory/tino-prod/inventory.ini remove-node.yml -e node="k8s-worker-2" --ask-vault-pass
```

---

Idea is to have this kind of env at the and with all services around kubespray:

![alt text](./tino-external-iac.jpeg?raw=true "Tino - Kubernetes Enviroment")

