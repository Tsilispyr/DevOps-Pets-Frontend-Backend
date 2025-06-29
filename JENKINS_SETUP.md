# Jenkins Pipeline Setup Guide

## Overview
This Jenkins pipeline builds and deploys the frontend and backend applications using system tools from localhost.

## Prerequisites

### Required Tools (must be in system PATH):
- **Java 17+** - for backend compilation
- **Maven 3.9.5+** - for Java build
- **Node.js 18+** - for frontend build
- **npm** - comes with Node.js
- **Docker** - for containerization
- **kubectl** - for Kubernetes deployment

### Check Tools Availability:
```bash
chmod +x check-tools.sh
./check-tools.sh
```

## Setup Steps

### 1. Install Missing Tools (if any)

#### Java 17:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-17-jdk

# Windows
# Download from: https://adoptium.net/temurin/releases/?version=17
```

#### Node.js 18:
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows
# Download from: https://nodejs.org/en/download/
```

#### Docker:
```bash
# Ubuntu/Debian
sudo apt install docker.io
sudo usermod -aG docker $USER

# Windows
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
```

#### kubectl:
```bash
# Ubuntu/Debian
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl/
```

### 2. Jenkins Configuration

#### Required Jenkins Credentials:
- **jenkins-kubeconfig-text** - Kubernetes config file content

#### Jenkins Tools:
- **Maven 3.9.5** - should be configured in Jenkins

### 3. Start Devpets-main Services

Before running the pipeline, ensure the Devpets-main services are running:

```bash
# From Devpets-main directory
./start-port-forwards.sh
```

This will start port forwarding for:
- PostgreSQL: localhost:5432
- MailHog UI: http://localhost:8025
- MailHog SMTP: localhost:1025

## Pipeline Stages

1. **Checkout** - Clone the repository
2. **Build Java Application** - Compile backend with Maven
3. **Build Frontend** - Build Vue.js application with npm
4. **Build Docker Images** - Create container images
5. **Deploy to Kubernetes** - Deploy to cluster (main branch only)

## Access Points

After successful deployment:
- **Backend API**: http://localhost:30080
- **Frontend App**: http://localhost:30000
- **MailHog UI**: http://localhost:8025
- **PostgreSQL**: localhost:5432

## Troubleshooting

### Common Issues:

1. **Java version error**: Ensure Java 17+ is installed and in PATH
2. **Node.js not found**: Install Node.js 18+ and ensure it's in PATH
3. **Docker permission error**: Add user to docker group or run with sudo
4. **kubectl connection error**: Check kubeconfig and cluster status

### Check Pipeline Logs:
- Go to Jenkins job → Console Output
- Look for specific error messages
- Verify all tools are available in the Jenkins environment

## Notes

- The pipeline uses system tools instead of Jenkins-managed tools for simplicity
- All tools must be available in the Jenkins agent's PATH
- The pipeline only deploys from the 'main' branch
- Docker images are built locally and must be accessible to the Kubernetes cluster 