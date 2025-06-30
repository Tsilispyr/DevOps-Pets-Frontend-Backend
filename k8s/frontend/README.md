# Frontend Kubernetes Deployment

## Overview

This directory contains Kubernetes manifests for deploying the Vue.js frontend application. The frontend serves as the user interface for the pet adoption management system and includes nginx for static file serving and API proxying.

## Files

### frontend-deployment.yaml
Vue.js application deployment configuration with the following features:

- **Container Image**: nginx:alpine
- **Application Port**: 80
- **Health Checks**: Readiness and liveness probes
- **Resource Limits**: CPU and memory constraints
- **Volume Mounts**: Shared storage for dist files, nginx config
- **Init Container**: Copies built dist files from shared storage
- **ConfigMap**: Nginx configuration for API routing

### frontend-service.yaml
LoadBalancer service configuration for external access:

- **Service Type**: LoadBalancer
- **External Port**: 80 (Standard)
- **Target Port**: 80
- **External Access**: Available via cluster IP
- **Session Affinity**: None (stateless)

## Configuration Details

### Nginx Configuration
The frontend uses nginx to serve static files and proxy API requests to the backend:

```nginx
server {
    listen 80;
    server_name localhost;
    
    # Serve static files
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
        index index.html;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://backend-service:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Resource Limits
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Volume Mounts
```yaml
volumeMounts:
- name: shared-storage
  mountPath: /shared
- name: nginx-config
  mountPath: /etc/nginx/conf.d/default.conf
  subPath: nginx.conf
```

## Deployment Process

1. **Build Application**: Jenkins builds Vue.js application with Vite
2. **Copy to Storage**: Dist files copied to shared PVC
3. **Deploy Pod**: Kubernetes creates frontend pod
4. **Init Container**: Copies dist files from shared storage
5. **Start Nginx**: Nginx serves static files and proxies API
6. **Health Check**: Probes verify nginx readiness

## Dependencies

- **Backend Service**: API proxy target
- **Shared Storage**: PVC for dist file sharing
- **ConfigMap**: Nginx configuration
- **RBAC**: Service account permissions

## Features

### Static File Serving
- **Root Directory**: /usr/share/nginx/html
- **SPA Routing**: Fallback to index.html for client-side routing
- **File Types**: HTML, CSS, JavaScript, images, fonts
- **Caching**: Browser caching headers

### API Proxying
- **Backend Target**: backend-service:8080
- **Path Rewriting**: /api/ → /
- **Header Forwarding**: Host, X-Real-IP, X-Forwarded-For
- **Load Balancing**: Multiple backend instances

### Security
- **CORS Headers**: Cross-origin request handling
- **Security Headers**: XSS protection, content type sniffing
- **Request Limiting**: Rate limiting capabilities
- **SSL Termination**: HTTPS support (if configured)

## Monitoring

- **Health Endpoint**: /health
- **Access Logs**: Nginx access logging
- **Error Logs**: Nginx error logging
- **Resource Usage**: CPU and memory monitoring

## Troubleshooting

### Common Issues

#### Frontend Not Loading
```bash
# Check pod logs
kubectl logs frontend-deployment-xxx -n devops-pets

# Check pod events
kubectl describe pod frontend-deployment-xxx -n devops-pets
```

#### API Proxy Issues
```bash
# Test nginx configuration
kubectl exec -it frontend-deployment-xxx -n devops-pets -- nginx -t

# Check nginx logs
kubectl exec -it frontend-deployment-xxx -n devops-pets -- tail -f /var/log/nginx/error.log
```

#### Static Files Missing
```bash
# Check shared storage
kubectl exec -it frontend-deployment-xxx -n devops-pets -- ls -la /shared

# Verify dist files exist
kubectl exec -it frontend-deployment-xxx -n devops-pets -- ls -la /usr/share/nginx/html
```

### Debugging Commands
```bash
# Port forward to frontend
kubectl port-forward frontend-deployment-xxx 80:80 -n devops-pets

# Execute shell in pod
kubectl exec -it frontend-deployment-xxx -n devops-pets -- /bin/sh

# Test nginx configuration
kubectl exec -it frontend-deployment-xxx -n devops-pets -- nginx -T
```

## Scaling

### Manual Scaling
```bash
# Scale to 2 replicas
kubectl scale deployment frontend-deployment --replicas=2 -n devops-pets
```

### Auto Scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-deployment
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Performance Optimization

### Nginx Configuration
- **Gzip Compression**: Enable for text files
- **Browser Caching**: Cache static assets
- **Connection Pooling**: Optimize backend connections
- **Buffer Sizes**: Optimize for application traffic

### Static File Optimization
- **Minification**: CSS and JavaScript minification
- **Image Optimization**: WebP format support
- **Font Loading**: Optimize font loading
- **CDN Integration**: External CDN support

## Security Considerations

- **Content Security Policy**: XSS protection
- **HTTPS Enforcement**: Secure communication
- **Request Validation**: Input sanitization
- **Rate Limiting**: Prevent abuse
- **Access Control**: IP-based restrictions

## Maintenance

### Configuration Updates
```bash
# Update nginx config
kubectl apply -f nginx-config.yaml

# Restart frontend deployment
kubectl rollout restart deployment frontend-deployment -n devops-pets
```

### Log Rotation
- **Access Logs**: Rotate based on size/time
- **Error Logs**: Monitor for issues
- **Log Aggregation**: Centralized logging

### Backup
- **Configuration**: Version control for nginx config
- **Static Files**: Backup of built application
- **Logs**: Archive access and error logs 