# DevOps Pets - Frontend & Backend

A complete DevOps project with frontend (Vue.js) and backend (Spring Boot) applications, deployed using Jenkins pipeline to Kubernetes.

## Project Structure

```
F-B-END/
├── Ask/                    # Spring Boot Backend Application
├── frontend/              # Vue.js Frontend Application
├── k8s/                   # Kubernetes Manifests
├── Jenkinsfile           # Jenkins Pipeline
├── JENKINS_SETUP.md      # Setup Instructions
└── README.md             # This file
```

## Applications

### Backend (Spring Boot)
- **Technology**: Spring Boot 3.3.8, Java 17
- **Database**: PostgreSQL
- **Features**: REST API, JWT Authentication, Email Service
- **Port**: 30080 (NodePort)

### Frontend (Vue.js)
- **Technology**: Vue 3, Vite, Pinia
- **Features**: Modern SPA, State Management, Router
- **Port**: 30000 (NodePort)

## Infrastructure

### Services (from Devpets-main)
- **PostgreSQL**: localhost:5432
- **MailHog UI**: http://localhost:8025
- **MailHog SMTP**: localhost:1025
- **Jenkins**: http://localhost:8082

### Docker Registry
- **Registry**: http://localhost:5000

## Quick Start

### Prerequisites
- Java 17+
- Node.js 18+
- Docker
- kubectl
- kind
- Maven 3.9.5+

### Setup Steps

1. **Start Devpets-main Infrastructure**
   ```bash
   cd ../Devpets-main
   ./start-port-forwards.sh
   ```

2. **Run Jenkins Pipeline**
   - Go to Jenkins UI: http://localhost:8082
   - Create new pipeline job
   - Point to this repository
   - Run the pipeline

3. **Access Applications**
   - Backend API: http://localhost:30080
   - Frontend App: http://localhost:30000
   - MailHog UI: http://localhost:8025

## Jenkins Pipeline

The pipeline automatically:
- Sets up Docker registry
- Builds applications
- Creates Docker images
- Deploys to Kubernetes
- Sets up port forwarding
- Verifies deployment

### Pipeline Stages
1. Setup Docker Registry
2. Complete Cleanup
3. Build Applications
4. Build & Push Images
5. Load to Cluster
6. Update Manifests
7. Deploy to Kubernetes
8. Setup Port Forwarding
9. Verify Deployment

## Development

### Backend Development
```bash
cd Ask
mvn spring-boot:run
```

### Frontend Development
```bash
cd frontend
npm install
npm run dev
```

### Database
The backend connects to PostgreSQL running in the Devpets-main cluster:
- Host: postgres.default.svc.cluster.local
- Database: petdb
- Username: petuser
- Password: petpass

### Email Service
Uses MailHog for email testing:
- SMTP Host: mailhog
- SMTP Port: 1025
- Web UI: http://localhost:8025

## Configuration

### Environment Variables
- `SPRING_DATASOURCE_URL`: jdbc:postgresql://postgres:5432/petdb
- `SPRING_MAIL_HOST`: mailhog
- `SPRING_MAIL_PORT`: 1025

### Kubernetes Configuration
- Namespace: devops-pets
- Cluster: devops-pets (kind)
- Image Registry: localhost:5000

## Troubleshooting

### Common Issues
1. **Port forwarding not working**: Check if services are deployed
2. **Database connection errors**: Verify PostgreSQL is running
3. **Image pull errors**: Check Docker registry
4. **Build failures**: Verify tool versions

### Useful Commands
```bash
# Check cluster status
kubectl get all -n devops-pets

# View logs
kubectl logs -n devops-pets <pod-name>

# Check port forwarding
netstat -tlnp | grep -E "(30080|30000)"

# Stop port forwarding
pkill -f 'kubectl port-forward'
```

## Architecture

### Frontend
- Vue 3 with Composition API
- Pinia for state management
- Vue Router for navigation
- Axios for API calls
- Vite for build tooling

### Backend
- Spring Boot 3.3.8
- Spring Security with JWT
- Spring Data JPA
- PostgreSQL database
- MailHog for email testing

### Infrastructure
- Kubernetes (kind) for orchestration
- Docker for containerization
- Jenkins for CI/CD
- Local Docker registry
- NodePort services for external access

## Contributing

1. Make changes to frontend or backend
2. Commit to any branch
3. Run Jenkins pipeline
4. Verify deployment
5. Test functionality

## Notes

- All services run in devops-pets namespace
- Images are tagged with BUILD_NUMBER
- Old images are automatically cleaned
- Port forwarding is managed by pipeline
- No manual setup required after initial configuration
