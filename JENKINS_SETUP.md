# Οδηγός Ρύθμισης Jenkins

Αυτός ο οδηγός εξηγεί πώς να ρυθμίσετε και να εκτελέσετε το pipeline Jenkins για την εφαρμογή DevPets.

## Προαπαιτούμενα

1. **Υποδομή Devpets-main**: Βεβαιωθείτε ότι το Devpets-main έχει αναπτυχθεί πρώτα
   - Το Jenkins πρέπει να τρέχει στο https://pet-system-devpets.swedencentral.cloudapp.azure.com
   - Το Kubernetes cluster (kind ή cloud) να είναι ενεργό με namespace `devops-pets`
   - PostgreSQL και MailHog να έχουν αναπτυχθεί στο cluster

2. **Εργαλεία Jenkins**: Τα παρακάτω εργαλεία πρέπει να είναι διαθέσιμα στο Jenkins:
   - Maven 3.9.5
   - Node.js (για npm)
   - kubectl (για Kubernetes)

## Ρύθμιση Pipeline Jenkins

### 1. Δημιουργία Νέου Pipeline Job

1. Μεταβείτε στο Jenkins UI: https://pet-system-devpets.swedencentral.cloudapp.azure.com
2. Κάντε κλικ στο "New Item"
3. Δώστε όνομα: `Devpets`
4. Επιλέξτε "Pipeline"
5. Κλικ "OK"

### 2. Ρύθμιση Pipeline

1. **Γενικές Ρυθμίσεις**:
   - Επιλέξτε "Discard old builds" (κρατήστε τα τελευταία 10 builds)

2. **Pipeline Definition**:
   - Επιλέξτε "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: Το URL του repository σας
   - Branch: `*/main` (ή το default branch σας)
   - Script Path: `Jenkinsfile`

3. **Build Triggers**:
   - Poll SCM: `H/5 * * * *` (κάθε 5 λεπτά)
   - Ή χρησιμοποιήστε webhooks για αυτόματα builds

### 3. Αποθήκευση και Εκτέλεση

1. Κλικ "Save"
2. Κλικ "Build Now" για δοκιμή του pipeline

## Ροή Pipeline

Το pipeline εκτελεί τα εξής βήματα:

### 1. Πλήρες Cleanup
- Σταματά υπάρχοντα port forwarding
- Διαγράφει παλιά deployments και services
- Καθαρίζει orphaned pods

### 2. Build Εφαρμογών
- **Backend**: Κάνει compile το Spring Boot JAR με Maven
- **Frontend**: Κάνει build το Vue.js app με npm

### 3. Προετοιμασία Αρχείων
- Αντιγράφει το JAR στο target directory
- Επαληθεύει το build του frontend

### 4. Ενημέρωση Manifests
- Ενημερώνει τα Kubernetes manifests για χρήση hostPath volumes
- Backend: Χρήση openjdk:17-jdk-slim image με mounted JAR
- Frontend: Χρήση nginx:stable-alpine image με mounted dist

### 5. Ανάπτυξη στο Kubernetes
- Εφαρμόζει όλα τα Kubernetes manifests
- Περιμένει να είναι έτοιμα τα deployments
- Επαληθεύει ότι όλα τα pods τρέχουν

### 6. Ρύθμιση Port Forwarding (μόνο για τοπική ανάπτυξη)
- Backend: localhost:30080 → 8080
- Frontend: localhost:30000 → 80

### 7. Επαλήθευση Ανάπτυξης
- Ελέγχει ότι όλα τα services τρέχουν
- Επαληθεύει τις υποδομές
- Επιβεβαιώνει την επιτυχία του deployment

## Σημεία Πρόσβασης

Μετά από επιτυχή ανάπτυξη:

- **Frontend**: https://pet-system-devpets.swedencentral.cloudapp.azure.com
- **Backend API**: https://pet-system-devpets.swedencentral.cloudapp.azure.com/api
- **MailHog UI**: http://localhost:8025
- **PostgreSQL**: localhost:5432 (μόνο internal)
- **Jenkins**: https://pet-system-devpets.swedencentral.cloudapp.azure.com

## Επίλυση Προβλημάτων

### Συχνά Προβλήματα

1. **Αποτυχία Build**:
   - Ελέγξτε αν Maven και Node.js υπάρχουν στο Jenkins
   - Επαληθεύστε τη συμβατότητα Java (Java 17)
   - Ελέγξτε τα build logs για σφάλματα

2. **Αποτυχία Ανάπτυξης**:
   - Βεβαιωθείτε ότι το kubectl είναι σωστά ρυθμισμένο
   - Ελέγξτε αν υπάρχει το namespace `devops-pets`
   - Ελέγξτε αν οι υπηρεσίες υποδομής τρέχουν

3. **Προβλήματα Port Forwarding** (μόνο τοπικά):
   - Ελέγξτε αν οι θύρες 30000/30080 είναι διαθέσιμες
   - Επαληθεύστε ότι τα port forwarding processes τρέχουν
   - Επανεκκινήστε το port forwarding αν χρειάζεται

### Χρήσιμες Εντολές

```bash
# Έλεγχος εργαλείων Jenkins
which mvn
which node
which kubectl

# Έλεγχος cluster
kubectl cluster-info
kubectl get nodes

# Έλεγχος namespace
kubectl get namespace devops-pets

# Έλεγχος όλων των πόρων
kubectl get all -n devops-pets

# Προβολή logs
kubectl logs -n devops-pets <pod-name>

# Σταμάτημα port forwarding
pkill -f 'kubectl port-forward'
```

### Τοποθεσίες Logs

- **Jenkins Build Logs**: Μέσα από το Jenkins UI
- **Application Logs**: `kubectl logs -n devops-pets <pod-name>`
- **System Logs**: Jenkins container logs

## Σημειώσεις

- Το pipeline χρησιμοποιεί hostPath volumes αντί για Docker images
- Δεν απαιτείται Docker registry
- Standard images (openjdk, nginx) κατεβαίνουν από Docker Hub
- Το port forwarding διαχειρίζεται αυτόματα από το pipeline (μόνο τοπικά)
- Όλες οι υποδομές παρέχονται από το Devpets-main

## Θέματα Ασφαλείας

- Το pipeline τρέχει με δικαιώματα χρήστη Jenkins
- Τα hostPath volumes κάνουν mount directories του workspace Jenkins
- Το port forwarding εκθέτει υπηρεσίες μόνο στο localhost
- Δεν απαιτείται εξωτερικό registry ή push images

---

**Cloud/HTTPS Σημείωση:**
Για cloud περιβάλλον, η πρόσβαση γίνεται μέσω HTTPS και Ingress controller με cert-manager για αυτόματη έκδοση SSL certificates. 