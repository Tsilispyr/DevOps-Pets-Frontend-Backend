# F-B-END (Frontend & Backend Application)

## Περιγραφή
Το F-B-END είναι το application κομμάτι του DevPets. Περιλαμβάνει:
- Spring Boot backend (Java 17, JWT, PostgreSQL, MinIO, Mailhog)
- Vue.js frontend (Vite, Pinia, Bootstrap)
- Όλα τα Kubernetes manifests για deployment
- **HTTPS ingress με cert-manager**
- Jenkinsfile για CI/CD pipeline

## Σύνδεση με Dpet
Το F-B-END τρέχει πάνω στο Kubernetes cluster που στήνει το Dpet. Το deployment γίνεται αυτόματα μέσω Jenkins pipeline που τρέχει μέσα στο cluster. Η επικοινωνία frontend-backend γίνεται μέσω Ingress και services.

## Δομή
```
F-B-END/
├── Ask/                # Spring Boot backend
├── frontend/           # Vue.js frontend
├── k8s/                # Kubernetes manifests (backend, frontend, storage, κλπ)
├── Jenkinsfile         # CI/CD pipeline (build, deploy, verify)
├── nginx-config.yaml   # Nginx config για frontend
└── README.md
```

## Βασικά Αρχεία
- **Jenkinsfile**: Ορίζει όλα τα βήματα του pipeline (checkout, build, deploy, ingress, port-forward, verification)
- **k8s/**: Όλα τα manifests για backend, frontend, storage, ingress, κλπ
- **frontend/**: Vue.js app (npm run dev για local dev)
- **Ask/**: Spring Boot app (./mvnw spring-boot:run για local dev)

## Ανάπτυξη (Development)
- **Backend**:
```bash
cd Ask
./mvnw spring-boot:run
```
- **Frontend**:
```bash
cd frontend
npm install
npm run dev
```

## Deployment (CI/CD)
1. **Αρχικό setup**: Στήσε το cluster μέσω Dpet (δες Dpet/README.md)
2. **Pipeline**:
   - Πρόσβαση στο Jenkins: http://localhost:8082
   - Δημιούργησε pipeline job που δείχνει σε αυτό το repo
   - Τρέξε το pipeline (checkout, build, deploy, verify, HTTPS)
3. **Πρόσβαση**:
   - **Local Development**:
     - Frontend: http://localhost:8081
     - Backend API: http://localhost:8080/api
     - MailHog: http://localhost:8025
     - MinIO: http://localhost:9000
   - **Cloud Production**:
     - Frontend: https://pet-system.com
     - Backend API: http://localhost:8080/api (port-forward)
     - MailHog: http://localhost:8025 (port-forward)

## Καθημερινή Χρήση
- Κάνε αλλαγές στον κώδικα (frontend ή backend)
- Κάνε commit/push ή τρέξε το pipeline στο Jenkins
- Πρόσβαση στις υπηρεσίες μέσω των παραπάνω URLs

## Troubleshooting
- Έλεγξε pods: `kubectl get pods -n devops-pets`
- Logs: `kubectl logs <pod> -n devops-pets`
- Services: `kubectl get svc -n devops-pets`
- Ingress: `kubectl get ingress -n devops-pets`
- **HTTPS/Certificates**: `kubectl get certificates -n devops-pets`
- **Cert-manager**: `kubectl get pods -n cert-manager`

## Σημειώσεις
- Όλα τα credentials περνάνε μέσω Kubernetes secrets
- **HTTPS certificates** δημιουργούνται αυτόματα από Let's Encrypt
- **Frontend είναι public HTTPS**, backend είναι internal με port-forwarding
- Για πλήρη αρχιτεκτονική και αυτοματοποίηση, δες το `FULL_PROJECT_OVERVIEW.md`
