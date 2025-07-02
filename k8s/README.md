# Ρυθμίσεις Ανάπτυξης Kubernetes

## Επισκόπηση

Αυτός ο φάκελος περιέχει όλα τα Kubernetes manifests για την ανάπτυξη των εφαρμογών F-B-END. Η ανάπτυξη ακολουθεί αρχιτεκτονική microservices με ξεχωριστές υπηρεσίες frontend και backend, κοινόχρηστη αποθήκευση και load balancing.

## Δομή Φακέλου

```
k8s/
├── backend/                    # Ανάπτυξη backend εφαρμογής
│   ├── backend-deployment.yaml # Spring Boot deployment
│   └── backend-service.yaml    # Service backend
├── frontend/                   # Ανάπτυξη frontend εφαρμογής
│   ├── frontend-deployment.yaml # Vue.js deployment
│   └── frontend-service.yaml   # Service frontend
├── shared-storage.yaml         # Κοινόχρηστη αποθήκευση
└── README.md                   # Τεκμηρίωση
```

## Συνιστώμενα Σημεία

### Ανάπτυξη Backend

#### backend-deployment.yaml
- **Εικόνα**: openjdk:17-jre-slim
- **Θύρα**: 8080
- **Πόροι**: Όρια CPU και μνήμης
- **Έλεγχοι Υγείας**: Readiness και liveness probes
- **Μεταβλητές Περιβάλλοντος**: Σύνδεση DB, JWT
- **Volume Mounts**: Κοινόχρηστη αποθήκευση για JAR
- **Init Container**: Αντιγραφή JAR από shared storage

#### backend-service.yaml
- **Τύπος**: LoadBalancer
- **Θύρα**: 8080
- **Target Port**: 8080
- **Εξωτερική Πρόσβαση**: Μέσω cluster IP

### Ανάπτυξη Frontend

#### frontend-deployment.yaml
- **Εικόνα**: nginx:alpine
- **Θύρα**: 80
- **Πόροι**: Όρια CPU και μνήμης
- **Έλεγχοι Υγείας**: Readiness και liveness probes
- **Volume Mounts**: Κοινόχρηστη αποθήκευση για dist, nginx config
- **Init Container**: Αντιγραφή dist από shared storage
- **ConfigMap**: Ρύθμιση nginx για API routing

#### frontend-service.yaml
- **Τύπος**: LoadBalancer
- **Θύρα**: 80
- **Target Port**: 80
- **Εξωτερική Πρόσβαση**: Μέσω cluster IP

### Κοινόχρηστη Αποθήκευση

#### shared-storage.yaml
- **Τύπος**: PersistentVolumeClaim
- **Storage Class**: Standard
- **Access Mode**: ReadWriteMany
- **Μέγεθος**: 1Gi
- **Σκοπός**: Κοινή χρήση artifacts μεταξύ Jenkins και pods εφαρμογών

## Αρχιτεκτονική Ανάπτυξης

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Access Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Browser   │  │   API Calls │  │   Jenkins   │            │
│  │  localhost   │  │  localhost   │  │   localhost  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Ingress Controller Layer                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              nginx-ingress-controller                       │ │
│  │  - Route / → frontend service                              │ │
│  │  - Route /api → backend service                            │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Service Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │            │
│  │ LoadBalancer│  │ LoadBalancer│  │ ClusterIP   │            │
│  │   :80       │  │   :8080     │  │   :5432     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Pod Layer                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │            │
│  │   Pod       │  │    Pod      │  │    Pod      │            │
│  │ nginx:alpine│  │ openjdk:17  │  │ postgres:15 │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Storage Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Shared    │  │  Jenkins    │  │ PostgreSQL  │            │
│  │   Storage   │  │   Storage   │  │   Storage   │            │
│  │   (PVC)     │  │   (PVC)     │  │   (PVC)     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Κύρια Χαρακτηριστικά

### Load Balancing
- **MetalLB LoadBalancer**: Παρέχει εξωτερικές IP
- **Service Discovery**: Εσωτερική επικοινωνία cluster
- **Health Checks**: Αυτόματη αποκατάσταση
- **Session Management**: Stateless design

### Διαχείριση Αποθήκευσης
- **Shared PVC**: Jenkins και pods μοιράζονται storage
- **Init Containers**: Αντιγραφή artifacts
- **Persistent Data**: Μόνιμα δεδομένα DB/Jenkins
- **Volume Mounts**: Πρόσβαση στο file system

### Ασφάλεια
- **RBAC**: Έλεγχος πρόσβασης
- **Service Accounts**: Αυθεντικοποίηση pods
- **Network Policies**: Απομόνωση traffic
- **Secrets Management**: Προστασία ευαίσθητων δεδομένων

### Παρακολούθηση
- **Health Probes**: Έλεγχος υγείας εφαρμογών
- **Resource Limits**: Όρια CPU/μνήμης
- **Logging**: Κεντρική συλλογή logs
- **Metrics**: Παρακολούθηση απόδοσης

## Ρυθμίσεις Backend

#### Μεταβλητές Περιβάλλοντος
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

#### Έλεγχοι Υγείας
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

## Ρυθμίσεις Frontend

#### Ρύθμιση Nginx
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

## Διαδικασία Ανάπτυξης

### 1. Υποδομή
```bash
# Εφαρμογή shared storage
kubectl apply -f shared-storage.yaml

# Εφαρμογή RBAC
kubectl apply -f rbac-config.yaml
```

### 2. Εφαρμογή
```bash
# Deploy backend
kubectl apply -f backend/

# Deploy frontend
kubectl apply -f frontend/
```

### 3. Επαλήθευση
```bash
# Έλεγχος pods
kubectl get pods -n devops-pets

# Έλεγχος services
kubectl get services -n devops-pets

# Έλεγχος ingress
kubectl get ingress -n devops-pets
```

## Απαιτήσεις Πόρων

### Backend Pod
- **CPU**: 500m (0.5 cores)
- **Μνήμη**: 512Mi
- **Αποθήκευση**: Shared volume

### Frontend Pod
- **CPU**: 200m (0.2 cores)
- **Μνήμη**: 256Mi
- **Αποθήκευση**: Shared volume

### Shared Storage
- **Μέγεθος**: 1Gi
- **Access Mode**: ReadWriteMany
- **Storage Class**: Standard

## Scaling

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
# Scale backend σε 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n devops-pets

# Scale frontend σε 2 replicas
kubectl scale deployment frontend-deployment --replicas=2 -n devops-pets
```

## Επίλυση Προβλημάτων

### Συχνά Προβλήματα

#### Pod δεν ξεκινά
```bash
# Έλεγχος pod events
kubectl describe pod <pod-name> -n devops-pets

# Έλεγχος logs pod
kubectl logs <pod-name> -n devops-pets
```

#### Service μη προσβάσιμο
```bash
# Έλεγχος endpoints
kubectl get endpoints -n devops-pets

# Τεστ συνδεσιμότητας
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup backend-service
```

#### Προβλήματα αποθήκευσης
```bash
# Έλεγχος PVC
kubectl get pvc -n devops-pets

# Έλεγχος PV
kubectl get pv
```

### Debugging
```bash
# Port forward για debug
kubectl port-forward <pod-name> 8080:8080 -n devops-pets

# Εκτέλεση εντολών σε pod
kubectl exec -it <pod-name> -n devops-pets -- /bin/sh

# Αντιγραφή αρχείων από/προς pod
kubectl cp <pod-name>:/path/to/file ./local-file -n devops-pets
```

## Συντήρηση

### Ενημερώσεις
- **Rolling Updates**: Zero-downtime deployments
- **Rollback**: Επιστροφή σε προηγούμενη έκδοση
- **Blue-Green**: Εναλλακτική στρατηγική ανάπτυξης
- **Canary**: Σταδιακή διάθεση

### Backup
- **Database**: Τακτικά backup PostgreSQL
- **Configuration**: Έλεγχος εκδόσεων manifests
- **Data**: Backup persistent volumes
- **Logs**: Κεντρική αποθήκευση logs

### Παρακολούθηση
- **Χρήση Πόρων**: Παρακολούθηση CPU/μνήμης
- **Υγεία Εφαρμογής**: Health checks
- **Δίκτυο**: Παρακολούθηση traffic
- **Αποθήκευση**: Παρακολούθηση χωρητικότητας

## Σημεία Πρόσβασης

### Εξωτερική Πρόσβαση
- **Frontend**: Port 80 (εξωτερικό IP από pipeline Jenkins)
- **Backend API**: Port 8080 (εξωτερικό IP από pipeline Jenkins)
- **Jenkins**: https://pet-system-devpets.swedencentral.cloudapp.azure.com
- **MailHog**: http://localhost:8025

### Εσωτερικές Υπηρεσίες
- **PostgreSQL**: postgres-service:5432
- **MailHog SMTP**: mailhog-service:1025
- **Kubernetes API**: kubernetes.default.svc

---

**Cloud/HTTPS Σημείωση:**
Για παραγωγική χρήση, προτείνεται η χρήση Ingress με HTTPS termination και cert-manager για αυτόματη έκδοση SSL certificates. 