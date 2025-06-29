# Jenkins Pipeline Setup Guide

## Overview
This Jenkins pipeline builds and deploys the frontend and backend applications with fresh Docker images every time. It uses a local Docker registry and ensures clean deployments by removing old resources before deploying new ones.

## Prerequisites

### Required Tools (must be in system PATH):
- **Java 17+** - for backend compilation
- **Maven 3.9.5+** - for Java build
- **Node.js 18+** - for frontend build
- **npm** - comes with Node.js
- **Docker** - for building and pushing images
- **kubectl** - for Kubernetes deployment

### Check Tools Availability:
```bash
# Check if tools are available
java -version
mvn -version
node --version
npm --version
docker --version
kubectl version --client
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

### 2. Setup Local Docker Registry

```bash
chmod +x setup-docker-registry.sh
./setup-docker-registry.sh
```

This will start a local Docker registry on `localhost:5000` where images will be stored.

### 3. Jenkins Configuration

#### Required Jenkins Credentials:
- **jenkins-kubeconfig-text** - Kubernetes config file content

#### Jenkins Tools:
- **Maven 3.9.5** - should be configured in Jenkins

### 4. Start Devpets-main Services

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
2. **Clean Kubernetes Resources** - Remove existing deployments and services
3. **Build Java Application** - Compile backend with Maven
4. **Build Frontend** - Build Vue.js application with npm
5. **Build and Push Docker Images** - Create fresh images and push to registry
6. **Update Kubernetes Manifests** - Update image tags in deployment files
7. **Deploy to Kubernetes** - Deploy fresh images to cluster
8. **Verify Deployment** - Check deployment status

## Deployment Method

The pipeline ensures fresh deployments every time:

- **Cleans existing resources** before deployment
- **Builds fresh Docker images** with unique tags (BUILD_NUMBER)
- **Pushes to local registry** (localhost:5000)
- **Updates manifests** with new image tags
- **Deploys fresh images** to Kubernetes
- **Cleans old images** after successful deployment

## Access Points

After successful deployment:
- **Backend API**: http://localhost:30080
- **Frontend App**: http://localhost:30000
- **MailHog UI**: http://localhost:8025
- **PostgreSQL**: localhost:5432
- **Docker Registry**: http://localhost:5000

## Manual Cleanup

If you need to manually clean the cluster:

```bash
chmod +x clean-cluster.sh
./clean-cluster.sh
```

## Troubleshooting

### Common Issues:

1. **Docker registry not accessible**: Ensure Docker registry is running on localhost:5000
2. **Image pull errors**: Check if images were pushed successfully to registry
3. **Kubernetes connection errors**: Verify kubeconfig and cluster status
4. **Build failures**: Check Java/Node.js versions and dependencies

### Check Pipeline Logs:
- Go to Jenkins job → Console Output
- Look for specific error messages
- Verify all tools are available in the Jenkins environment

## Notes

- Each build creates fresh images with unique tags
- Old deployments are automatically cleaned before new deployment
- Docker registry stores images locally for faster access
- Pipeline only deploys from the 'main' branch
- Automatic cleanup of old Docker images (keeps last 5 builds) 