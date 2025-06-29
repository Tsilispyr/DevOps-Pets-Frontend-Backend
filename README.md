# DevPets Application

A full-stack pet adoption management system with Spring Boot backend and Vue.js frontend.

## Architecture

This project contains:
- **Backend**: Spring Boot application with JWT authentication
- **Frontend**: Vue.js application with modern UI
- **Infrastructure**: Kubernetes deployment with hostPath volumes

## Prerequisites

- Jenkins (deployed via Devpets-main)
- Kubernetes cluster (kind) with namespace `devops-pets`
- PostgreSQL and MailHog (deployed via Devpets-main)
- kubectl configured to access the cluster

## Cluster Connection

### How Jenkins Connects to the Local Cluster

The Jenkins pipeline connects to the local Kubernetes cluster using the `jenkins-kubeconfig` file:

1. **Kubeconfig Setup**: The pipeline copies `jenkins-kubeconfig` to `~/.kube/config`
2. **Cluster Authentication**: Uses the provided service account token for authentication
3. **Namespace Management**: Creates or verifies the `devops-pets` namespace exists
4. **Cluster Verification**: Tests the connection with `kubectl cluster-info`

### Kubeconfig Details

The `jenkins-kubeconfig` file contains:
- **Cluster Server**: `https://127.0.0.1:6445` (kind cluster API server)
- **Authentication**: Service account token for `jenkins-admin`
- **Context**: `kind-devops-pets`
- **Security**: `insecure-skip-tls-verify: true` for local development

## Deployment

The application is deployed via Jenkins pipeline that:

1. **Sets up kubeconfig** for cluster access
2. **Builds** the Spring Boot JAR and Vue.js dist files
3. **Deploys** to Kubernetes using hostPath volumes
4. **Sets up** port forwarding for local access
5. **Verifies** deployment status

### Access Points

After successful deployment:
- **Frontend**: http://localhost:30000
- **Backend API**: http://localhost:30080
- **MailHog UI**: http://localhost:8025
- **PostgreSQL**: localhost:5432

### Pipeline Stages

1. **Setup Kubeconfig** - Configures cluster access
2. **Complete Cleanup** - Removes old deployments and port forwards
3. **Build Java Application** - Compiles Spring Boot JAR
4. **Build Frontend** - Builds Vue.js application
5. **Prepare Files** - Prepares files for deployment
6. **Update Manifests** - Updates Kubernetes manifests with hostPath volumes
7. **Deploy to Kubernetes** - Applies manifests and waits for readiness
8. **Setup Port Forwarding** - Establishes port forwards for local access
9. **Verify Deployment** - Confirms all services are running

## Development

### Backend (Spring Boot)
- Java 17
- Spring Boot 3.x
- JWT Authentication
- PostgreSQL database
- MailHog for email testing

### Frontend (Vue.js)
- Vue 3 with Composition API
- Vite build tool
- Modern responsive UI
- JWT token management

## Infrastructure

The application runs in the `devops-pets` namespace alongside:
- PostgreSQL database
- MailHog email service
- Jenkins CI/CD

## Troubleshooting

### Common Issues

1. **Port forwarding fails**: Check if ports 30000/30080 are available
2. **Database connection fails**: Verify PostgreSQL is running in the cluster
3. **Build failures**: Ensure Maven and Node.js are available in Jenkins
4. **Cluster connection fails**: Verify the kubeconfig file is correct and cluster is running

### Useful Commands

```bash
# Check deployment status
kubectl get all -n devops-pets

# View logs
kubectl logs -n devops-pets <pod-name>

# Stop port forwarding
pkill -f 'kubectl port-forward'

# Check infrastructure services
kubectl get services -n devops-pets

# Test cluster connection
kubectl cluster-info
kubectl get nodes
```

## Notes

- The pipeline uses hostPath volumes to mount built files directly
- No Docker registry is required - uses standard images (openjdk, nginx)
- Port forwarding is managed by the Jenkins pipeline
- All infrastructure services are provided by Devpets-main deployment
- Cluster connection is established via kubeconfig file with service account token
