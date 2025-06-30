# Backend Kubernetes Deployment

## Overview

This directory contains Kubernetes manifests for deploying the Spring Boot backend application. The backend provides RESTful APIs for the pet adoption management system.

## Files

### backend-deployment.yaml
Spring Boot application deployment configuration with the following features:

- **Container Image**: openjdk:17-jre-slim
- **Application Port**: 8080
- **Health Checks**: Readiness and liveness probes
- **Resource Limits**: CPU and memory constraints
- **Environment Variables**: Database and email configuration
- **Volume Mounts**: Shared storage for JAR file
- **Init Container**: Copies built JAR from shared storage

### backend-service.yaml
LoadBalancer service configuration for external access:

- **Service Type**: LoadBalancer
- **External Port**: 8080 (Standard)
- **Target Port**: 8080
- **External Access**: Available via cluster IP
- **Session Affinity**: None (stateless)

## Configuration Details

### Environment Variables
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

### Health Checks
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

### Resource Limits
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Deployment Process

1. **Build Application**: Jenkins builds Spring Boot JAR
2. **Copy to Storage**: JAR file copied to shared PVC
3. **Deploy Pod**: Kubernetes creates backend pod
4. **Init Container**: Copies JAR from shared storage
5. **Start Application**: Java application starts with JAR
6. **Health Check**: Probes verify application readiness

## Dependencies

- **PostgreSQL**: Database service (managed by Devpets-main)
- **MailHog**: Email service (managed by Devpets-main)
- **Shared Storage**: PVC for JAR file sharing
- **RBAC**: Service account permissions

## Monitoring

- **Health Endpoint**: /actuator/health
- **Application Logs**: Spring Boot logging
- **Resource Usage**: CPU and memory monitoring
- **Database Connectivity**: Connection pool monitoring

## Troubleshooting

### Common Issues

#### Application Not Starting
```bash
# Check pod logs
kubectl logs backend-deployment-xxx -n devops-pets

# Check pod events
kubectl describe pod backend-deployment-xxx -n devops-pets
```

#### Database Connection Issues
```bash
# Verify PostgreSQL service
kubectl get service postgres-service -n devops-pets

# Test database connectivity
kubectl exec -it backend-deployment-xxx -n devops-pets -- curl postgres-service:5432
```

#### JAR File Issues
```bash
# Check shared storage
kubectl exec -it backend-deployment-xxx -n devops-pets -- ls -la /shared

# Verify JAR file exists
kubectl exec -it backend-deployment-xxx -n devops-pets -- ls -la /app/app.jar
```

### Debugging Commands
```bash
# Port forward to backend
kubectl port-forward backend-deployment-xxx 8080:8080 -n devops-pets

# Execute shell in pod
kubectl exec -it backend-deployment-xxx -n devops-pets -- /bin/sh

# Check environment variables
kubectl exec -it backend-deployment-xxx -n devops-pets -- env | grep SPRING
```

## Scaling

### Manual Scaling
```bash
# Scale to 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n devops-pets
```

### Auto Scaling
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

## Security

- **Service Account**: Limited permissions via RBAC
- **Network Policy**: Traffic isolation
- **Secrets**: Database credentials (currently in plain text)
- **Health Checks**: Application security monitoring

## Performance

- **JVM Options**: Optimized for container environment
- **Connection Pool**: Database connection management
- **Caching**: Application-level caching
- **Resource Limits**: Prevent resource exhaustion 