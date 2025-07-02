# Kubernetes Deployment Configuration

## Overview

This directory contains all Kubernetes manifests for deploying the F-B-END application components. The deployment uses a microservices architecture with separate frontend and backend services, shared storage, and load balancing.

## Directory Structure

```
k8s/
├── backend/                    # Backend application deployment
│   ├── backend-deployment.yaml # Spring Boot application deployment
│   └── backend-service.yaml    # Backend service configuration
├── frontend/                   # Frontend application deployment
│   ├── frontend-deployment.yaml # Vue.js application deployment
│   └── frontend-service.yaml   # Frontend service configuration
├── shared-storage.yaml         # Shared storage configuration
└── README.md                   # This documentation
```

## Components

### Backend Deployment

#### backend-deployment.yaml
- **Image**: openjdk:17-jre-slim
- **Port**: 8080
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: Database connection, JWT configuration
- **Volume Mounts**: Shared storage for JAR file
- **Init Container**: Copies JAR file from shared storage

#### backend-service.yaml
- **Type**: LoadBalancer
- **Port**: 8080
- **Target Port**: 8080
- **External Access**: Available on cluster IP
- **Session Affinity**: None

### Frontend Deployment

#### frontend-deployment.yaml
- **Image**: nginx:alpine
- **Port**: 80
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes
- **Volume Mounts**: Shared storage for dist files, nginx config
- **Init Container**: Copies dist files from shared storage
- **ConfigMap**: Nginx configuration for API routing

#### frontend-service.yaml
- **Type**: LoadBalancer
- **Port**: 80
- **Target Port**: 80
- **External Access**: Available on cluster IP
- **Session Affinity**: None

### Shared Storage

#### shared-storage.yaml
- **Type**: PersistentVolumeClaim
- **Storage Class**: Standard
- **Access Mode**: ReadWriteMany
- **Size**: 1Gi
- **Purpose**: Share built artifacts between Jenkins and application pods

## Deployment Architecture

```
┌───────────────────────────────────────────────────────────┐
│                    External Access Layer                  │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │   Browser     │  │   API Calls   │  │   Jenkins     │  │
│  │ localhost:8081│  │ localhost:8080│  │ localhost:8082│  │
│  └───────────────┘  └───────────────┘  └───────────────┘  │
└───────────────────────────────────────────────────────────┘
                                │
┌──────────────────────────────────────────────────┐
│                    Ingress Controller Layer      │
│  ┌──────────────────────────────────────────────┐│
│  │              nginx-ingress-controlle         ││
│  │  - Route / → frontend service                ││
│  │  - Route /api → backend service              ││
│  └──────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
                                │
┌───────────────────────────────────────────────────────┐
│                    Service Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │    │
│  │ LoadBalancer│  │ LoadBalancer│  │ ClusterIP   │    │
│  │   :80       │  │   :8080     │  │   :5432     │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└───────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────┐
│                    Pod Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │  │
│  │   Pod       │  │    Pod      │  │    Pod      │  │
│  │ nginx:alpine│  │ openjdk:17  │  │ postgres:15 │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────┘
                                │ 
┌─────────────────────────────────────────────────────┐
│                    Storage Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Shared    │  │  Jenkins    │  │ PostgreSQL  │  │
│  │   Storage   │  │   Storage   │  │   Storage   │  │
│  │   (PVC)     │  │   (PVC)     │  │   (PVC)     │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Key Features

### Load Balancing
- **MetalLB LoadBalancer**: Provides external IP addresses
- **Service Discovery**: Internal cluster communication
- **Health Checks**: Automatic failover and recovery
- **Session Management**: Stateless application design

### Storage Management
- **Shared PVC**: Jenkins and application pods share storage
- **Init Containers**: Copy built artifacts to application pods
- **Persistent Data**: Database and Jenkins data persistence
- **Volume Mounts**: Proper file system access

### Security
- **RBAC**: Role-based access control
- **Service Accounts**: Pod authentication
- **Network Policies**: Traffic isolation
- **Secrets Management**: Sensitive data protection

### Monitoring
- **Health Probes**: Application health monitoring
- **Resource Limits**: CPU and memory constraints
- **Logging**: Centralized log collection
- **Metrics**: Performance monitoring

## Configuration Details

### Backend Configuration

#### Environment Variables
```yaml
- name: SPRING_DATASOURCE_URL
  value: "jdbc:postgresql://postgres-service:5432/petdb"
- name: SPRING_DATASOURCE_USERNAME
  value: "petuser"
- name: SPRING_DATASOURCE_PASSWORD
  value: "petpass"
- name: SPRING_MAIL_HOST
  value: "mailhog-service"
- name: SPRING_MAIL_PORT
  value: "1025"
```

#### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
```

### Frontend Configuration

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://backend-service:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Volume Mounts
```yaml
volumeMounts:
- name: shared-storage
  mountPath: /shared
- name: nginx-config
  mountPath: /etc/nginx/conf.d/default.conf
  subPath: nginx.conf
```

## Deployment Process

### 1. Infrastructure Setup
```bash
# Apply shared storage
kubectl apply -f shared-storage.yaml

# Apply RBAC configuration
kubectl apply -f rbac-config.yaml
```

### 2. Application Deployment
```bash
# Deploy backend
kubectl apply -f backend/

# Deploy frontend
kubectl apply -f frontend/
```

### 3. Verification
```bash
# Check pod status
kubectl get pods -n devops-pets

# Check services
kubectl get services -n devops-pets

# Check ingress
kubectl get ingress -n devops-pets
```

## Resource Requirements

### Backend Pod
- **CPU**: 500m (0.5 cores)
- **Memory**: 512Mi
- **Storage**: Shared volume access

### Frontend Pod
- **CPU**: 200m (0.2 cores)
- **Memory**: 256Mi
- **Storage**: Shared volume access

### Shared Storage
- **Size**: 1Gi
- **Access Mode**: ReadWriteMany
- **Storage Class**: Standard

## Scaling Configuration

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Manual Scaling
```bash
# Scale backend to 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n devops-pets

# Scale frontend to 2 replicas
kubectl scale deployment frontend-deployment --replicas=2 -n devops-pets
```

## Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n devops-pets

# Check pod logs
kubectl logs <pod-name> -n devops-pets
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n devops-pets

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup backend-service
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n devops-pets

# Check PV status
kubectl get pv
```

### Debugging Commands
```bash
# Port forward to debug
kubectl port-forward <pod-name> 8080:8080 -n devops-pets

# Execute commands in pod
kubectl exec -it <pod-name> -n devops-pets -- /bin/sh

# Copy files from/to pod
kubectl cp <pod-name>:/path/to/file ./local-file -n devops-pets
```

## Maintenance

### Updates
- **Rolling Updates**: Zero-downtime deployments
- **Rollback**: Quick rollback to previous versions
- **Blue-Green**: Alternative deployment strategy
- **Canary**: Gradual rollout for testing

### Backup
- **Database**: Regular PostgreSQL backups
- **Configuration**: Version control for manifests
- **Data**: Persistent volume backups
- **Logs**: Centralized log storage

### Monitoring
- **Resource Usage**: CPU and memory monitoring
- **Application Health**: Health check monitoring
- **Network Traffic**: Service communication monitoring
- **Storage Usage**: Volume capacity monitoring

## Access Points

### External Access
- **Frontend Application**: Port 80 (Standard) - External IP shown in Jenkins pipeline
- **Backend API**: Port 8080 (Standard) - External IP shown in Jenkins pipeline
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025

### Internal Services
- **PostgreSQL**: postgres-service:5432
- **MailHog SMTP**: mailhog-service:1025
- **Kubernetes API**: kubernetes.default.svc 
