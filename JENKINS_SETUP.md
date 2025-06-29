# Jenkins Setup Guide

This guide explains how to set up and run the Jenkins pipeline for the DevPets application.

## Prerequisites

1. **Devpets-main Infrastructure**: Ensure the Devpets-main project has been deployed first
   - Jenkins should be running on http://localhost:8082
   - Kubernetes cluster (kind) should be running with namespace `devops-pets`
   - PostgreSQL and MailHog should be deployed in the cluster

2. **Jenkins Tools**: The following tools should be available in Jenkins:
   - Maven 3.9.5
   - Node.js (for npm commands)
   - kubectl (for Kubernetes operations)

## Jenkins Pipeline Configuration

### 1. Create New Pipeline Job

1. Go to Jenkins UI: http://localhost:8082
2. Click "New Item"
3. Enter job name: `Devpets`
4. Select "Pipeline"
5. Click "OK"

### 2. Configure Pipeline

1. **General Settings**:
   - Check "Discard old builds" (keep last 10 builds)

2. **Pipeline Definition**:
   - Select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: Your repository URL
   - Branch: `*/main` (or your default branch)
   - Script Path: `Jenkinsfile`

3. **Build Triggers**:
   - Poll SCM: `H/5 * * * *` (every 5 minutes)
   - Or use webhooks for automatic builds

### 3. Save and Run

1. Click "Save"
2. Click "Build Now" to test the pipeline

## Pipeline Flow

The simplified pipeline performs the following steps:

### 1. Complete Cleanup
- Stops existing port forwarding
- Deletes old deployments and services
- Cleans up orphaned pods

### 2. Build Applications
- **Backend**: Compiles Spring Boot JAR using Maven
- **Frontend**: Builds Vue.js application using npm

### 3. Prepare Files
- Copies JAR file to target directory
- Verifies frontend build output

### 4. Update Manifests
- Updates Kubernetes manifests to use hostPath volumes
- Backend: Uses openjdk:17-jdk-slim image with JAR mounted
- Frontend: Uses nginx:stable-alpine image with dist files mounted

### 5. Deploy to Kubernetes
- Applies all Kubernetes manifests
- Waits for deployments to be ready
- Verifies all pods are running

### 6. Setup Port Forwarding
- Establishes port forwards for local access:
  - Backend: localhost:30080 → 8080
  - Frontend: localhost:30000 → 80

### 7. Verify Deployment
- Checks all services are running
- Verifies infrastructure services
- Confirms deployment success

## Access Points

After successful deployment:

- **Frontend Application**: http://localhost:30000
- **Backend API**: http://localhost:30080
- **MailHog UI**: http://localhost:8025
- **PostgreSQL**: localhost:5432
- **Jenkins**: http://localhost:8082

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check if Maven and Node.js are available in Jenkins
   - Verify Java version compatibility (Java 17)
   - Check build logs for specific errors

2. **Deployment Failures**:
   - Ensure kubectl is configured correctly
   - Verify the `devops-pets` namespace exists
   - Check if infrastructure services are running

3. **Port Forwarding Issues**:
   - Check if ports 30000/30080 are available
   - Verify port forwarding processes are running
   - Restart port forwarding if needed

### Useful Commands

```bash
# Check Jenkins tools
which mvn
which node
which kubectl

# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check namespace
kubectl get namespace devops-pets

# Check all resources
kubectl get all -n devops-pets

# View logs
kubectl logs -n devops-pets <pod-name>

# Stop port forwarding
pkill -f 'kubectl port-forward'
```

### Log Locations

- **Jenkins Build Logs**: Available in Jenkins UI
- **Application Logs**: `kubectl logs -n devops-pets <pod-name>`
- **System Logs**: Check Jenkins container logs

## Notes

- The pipeline uses hostPath volumes instead of Docker images
- No Docker registry is required
- Standard images (openjdk, nginx) are pulled from Docker Hub
- Port forwarding is managed automatically by the pipeline
- All infrastructure dependencies are provided by Devpets-main

## Security Considerations

- The pipeline runs with Jenkins user permissions
- hostPath volumes mount Jenkins workspace directories
- Port forwarding exposes services on localhost only
- No external registry or image pushing required 