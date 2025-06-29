# Ansible Deployment for DevOps Pets

This directory contains Ansible playbooks for deploying the DevOps Pets application to Kubernetes.

## Prerequisites

1. **Ansible** installed on the Jenkins agent
2. **kubectl** configured and accessible
3. **Kubernetes cluster** running and accessible

## Installation

### Install Ansible Collections
```bash
ansible-galaxy collection install -r requirements.yml
```

### Install kubectl (if not already installed)
```bash
# For Ubuntu/Debian
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# For CentOS/RHEL
sudo yum install -y kubectl
```

## Usage

### Manual Deployment
```bash
cd ansible
ansible-playbook deploy.yml -v
```

### From Jenkins Pipeline
The Jenkinsfile is configured to run this playbook automatically after building the Docker image.

## Playbooks

- **deploy.yml**: Deploys the backend application to Kubernetes
  - Applies backend deployment
  - Applies backend service
  - Waits for deployment to be ready
  - Displays deployment status

## Configuration

- **inventory.ini**: Defines the target hosts (localhost for local deployment)
- **ansible.cfg**: Ansible configuration settings
- **requirements.yml**: Required Ansible collections

## Troubleshooting

1. **kubectl not found**: Install kubectl and ensure it's in PATH
2. **Permission denied**: Ensure kubectl has proper permissions
3. **Connection refused**: Check if Kubernetes cluster is running
4. **Image pull error**: Ensure Docker image is built and available locally 