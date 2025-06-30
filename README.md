# F-B-END Project

## Overview

F-B-END is a comprehensive pet adoption management system consisting of a Spring Boot backend API and a Vue.js frontend application. The project includes complete CI/CD pipeline automation using Jenkins and Kubernetes deployment with automatic ingress setup and port forwarding.

## Project Structure

```
F-B-END/
├── Ask/                    # Spring Boot Backend Application
├── frontend/               # Vue.js Frontend Application
├── k8s/                    # Kubernetes Deployment Manifests
├── Jenkinsfile             # CI/CD Pipeline Configuration
├── nginx-config.yaml       # Nginx Configuration for Frontend
└── README.md               # This Documentation
```

## Components

### Backend (Ask/)
- **Technology**: Spring Boot 3.x with Java 17
- **Database**: PostgreSQL with JPA/Hibernate
- **Authentication**: JWT-based authentication and authorization
- **Features**: User management, animal listings, adoption requests, email verification

### Frontend (frontend/)
- **Technology**: Vue.js 3 with Composition API
- **Build Tool**: Vite
- **State Management**: Pinia
- **Routing**: Vue Router
- **UI Framework**: Bootstrap 5
- **Features**: Responsive design, user authentication, CRUD operations

### Infrastructure (k8s/)
- **Container Orchestration**: Kubernetes
- **Load Balancing**: MetalLB LoadBalancer
- **Ingress**: nginx-ingress-controller with automatic port forwarding
- **Storage**: PersistentVolumeClaims for shared data
- **Services**: LoadBalancer services for external access

## Prerequisites

- Docker Desktop with WSL2
- Kubernetes cluster (Kind cluster provided by Devpets-main)
- Jenkins (deployed via Devpets-main)
- Git

## Quick Start

1. **Infrastructure Setup** (if not already done):
   ```bash
   cd ../Devpets-main
   ./deploy
   ```

2. **Application Deployment**:
   - Access Jenkins at http://localhost:8082
   - Create new pipeline job pointing to this repository
   - Run the pipeline
   - Access application at http://localhost:3000

## Access Points

- **Frontend Application**: http://localhost:8081
- **Backend API**: http://localhost:8080/api
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025
- **PostgreSQL**: localhost:5432

## Communication Flow

The application uses a complete communication chain:

```
Local Browser ←→ Port Forwarding ←→ Ingress Controller ←→ Services ←→ Pods ←→ Database/Email
   :3000              :3000:80           :80              :8080      :8080      :5432/1025
```

### Detailed Flow:
1. **Browser** → **Port Forwarding** (localhost:3000 → ingress-controller:80)
2. **Ingress Controller** → **Services** (routing based on URL paths)
3. **Services** → **Pods** (service discovery and load balancing)
4. **Pods** → **Database/Email** (internal cluster communication)

## Development

### Backend Development
```bash
cd Ask
./mvnw spring-boot:run
```

### Frontend Development
```bash
cd frontend
npm install
npm run dev
```

## Deployment Architecture

The application uses a microservices architecture with:
- Separate frontend and backend containers
- Shared PostgreSQL database (managed by Devpets-main)
- Nginx reverse proxy for API routing
- LoadBalancer services for external access
- Ingress controller for unified access with automatic port forwarding
- MetalLB for LoadBalancer IP assignment

## Automated Pipeline Features

The Jenkins pipeline automatically:
1. **Sets up kubeconfig** for Jenkins authentication
2. **Installs MetalLB** LoadBalancer controller
3. **Builds applications** (frontend and backend)
4. **Deploys to Kubernetes** with shared storage
5. **Installs nginx-ingress** controller
6. **Adds ingress-ready labels** to nodes
7. **Configures ingress routing** with regex patterns
8. **Sets up port forwarding** on localhost:3000
9. **Provides access URLs** to the user

## Troubleshooting

### Common Issues
1. **Port forwarding not working**: Check if ingress controller is running
2. **Database connection errors**: Verify PostgreSQL is running in devops-pets namespace
3. **Frontend not loading**: Check nginx configuration and ConfigMap mounting
4. **Authentication issues**: Verify JWT configuration and database connectivity

### Useful Commands
```bash
# Check pod status
kubectl get pods -n devops-pets

# View logs
kubectl logs <pod-name> -n devops-pets

# Check services
kubectl get services -n devops-pets

# Check ingress
kubectl get ingress -n devops-pets

# Check ingress controller
kubectl get pods -n ingress-nginx

# Stop port forwarding
pkill -f "kubectl port-forward"
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test locally
5. Submit pull request

## License

This project is licensed under the MIT License.

## Notes
- The backend always listens on port 8080.
- The frontend is exposed on port 8081 via port-forward.
- Jenkins: http://localhost:8082
- MailHog: http://localhost:8025
