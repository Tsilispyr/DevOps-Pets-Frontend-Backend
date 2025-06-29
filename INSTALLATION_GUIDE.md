# DevOps Pets - Οδηγός Εγκατάστασης & Χρήσης

## 📋 Επισκόπηση

Αυτό το έγγραφο περιγράφει την απλοποιημένη διαδικασία για την εγκατάσταση, εκτέλεση και χρήση της εφαρμογής DevOps Pets σε ένα τοπικό περιβάλλον ανάπτυξης. Το σύστημα έχει σχεδιαστεί για να είναι πλήρως αυτοματοποιημένο και να απαιτεί ελάχιστες εξωτερικές εξαρτήσεις.

## 🔐 Σύστημα Αυθεντικοποίησης

Η εφαρμογή χρησιμοποιεί **JWT (JSON Web Token) authentication** για την ασφάλεια. Οι χρήστες μπορούν να εγγραφούν και να συνδεθούν μέσω της εφαρμογής χωρίς να χρειάζεται εξωτερικό σύστημα διαχείρισης χρηστών.

## ⚙️ Απαιτήσεις Συστήματος (Prerequisites)

Για να εκτελέσετε την εφαρμογή, χρειάζεστε μόνο **τρία** εργαλεία εγκατεστημένα στο σύστημά σας:

1.  **Docker & Docker Compose:** Απαραίτητο για τη δημιουργία των containers.
    *   [Οδηγίες εγκατάστασης Docker](https://docs.docker.com/get-docker/)
2.  **Kubernetes (μέσω `kind` ή `minikube`):** Ένα εργαλείο για την εκτέλεση τοπικών Kubernetes clusters.
    *   [Οδηγίες εγκατάστασης `kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (Linux/Mac)
    *   [Οδηγίες εγκατάστασης `minikube`](https://minikube.sigs.k8s.io/docs/start/) (Windows)
3.  **Git:** Για τη λήψη του πηγαίου κώδικα.
    *   [Οδηγίες εγκατάστασης Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

> **Σημείωση για Χρήστες Windows:** Συνιστάται η χρήση του **WSL 2 (Windows Subsystem for Linux)** για την εκτέλεση των παραπάνω εργαλείων, καθώς παρέχει την καλύτερη συμβατότητα.

## 🚀 Εγκατάσταση & Εκκίνηση

Η διαδικασία έχει αυτοματοποιηθεί πλήρως.

### Βήμα 1: Λήψη του Project

Ανοίξτε ένα terminal και κλωνοποιήστε το repository:
```bash
git clone https://github.com/Tsilispyr/Exercise_Ask_Kat.git
cd Exercise_Ask_Kat
```

### Βήμα 2: Εκτέλεση του Script Εγκατάστασης

#### **Για Linux/Mac:**
Εκτελέστε το bash script:
```bash
chmod +x devops-pets-up.sh
./devops-pets-up.sh
```

#### **Για Windows:**
Εκτελέστε το PowerShell script:
```powershell
.\devops-pets-up.ps1
```

Αυτά τα scripts θα αναλάβουν τα πάντα:
*   Θα δημιουργήσουν ένα καθαρό Kubernetes cluster (kind για Linux/Mac, minikube για Windows).
*   Θα χτίσουν τις Docker εικόνες για το backend και το frontend.
*   Θα τις φορτώσουν στο cluster.
*   Θα κάνουν deploy όλα τα απαραίτητα components (PostgreSQL, Backend, Frontend, Jenkins, Mailhog).
*   Θα ξεκινήσουν τα port-forwards για να έχετε άμεση πρόσβαση στις υπηρεσίες.

Το script θα παραμείνει ενεργό για να κρατήσει τις συνδέσεις port-forwarding ανοιχτές. Όταν τελειώσετε, απλά πατήστε `Ctrl+C` στο ίδιο terminal για να τερματιστούν τα πάντα.

## 🌐 Πρόσβαση στις Υπηρεσίες

Μετά την επιτυχή εκτέλεση του script, μπορείτε να αποκτήσετε πρόσβαση στις υπηρεσίες από τον browser σας στις παρακάτω διευθύνσεις:

*   **Frontend Εφαρμογή:** [http://localhost:8081](http://localhost:8081)
*   **Backend API (για tests):** [http://localhost:8080](http://localhost:8080)
*   **Mailhog (Email Testing):** [http://localhost:8025](http://localhost:8025)

### **🔧 Jenkins (Optional)**

Το Jenkins είναι **απενεργοποιημένο** από προεπιλογή για να επιταχύνει την εκκίνηση. Εάν χρειάζεστε Jenkins για CI/CD:

1. **Ενεργοποιήστε το:** Αποσχολιάστε τις γραμμές Jenkins στα scripts
2. **Πρόσβαση:** [http://localhost:8082](http://localhost:8082)
3. **Χρόνος εκκίνησης:** 2-3 λεπτά επιπλέον

**Για τα τεστ σας, το Jenkins δεν είναι απαραίτητο** καθώς δεν τρέχει tests και επαναλαμβάνει το build/deploy που ήδη κάνετε.

## 👥 Προκαθορισμένοι Χρήστες

Η εφαρμογή περιλαμβάνει τους εξής προκαθορισμένους χρήστες:

*   **User:** username: `user`, password: `user`
*   **Admin:** username: `admin`, password: `admin`
*   **Doctor:** username: `Doctor`, password: `Doctor`
*   **Shelter:** username: `shelter`, password: `shelter`

## 🔧 Πρώτη Ρύθμιση του Jenkins

Την **πρώτη φορά** που θα τρέξετε το σύστημα, το Jenkins θα χρειαστεί μια αρχική ρύθμιση που διαρκεί 2 λεπτά.

1.  **Ξεκλειδώστε το Jenkins:**
    *   Ανοίξτε ένα **νέο** terminal.
    *   Τρέξτε την εντολή: `cat ./jenkins_home/secrets/initialAdminPassword`
    *   Αντιγράψτε τον κωδικό που θα εμφανιστεί και επικολλήστε τον στην οθόνη του Jenkins.

2.  **Δημιουργήστε τον Admin χρήστη:** Ακολουθήστε τις οδηγίες για να δημιουργήσετε τον δικό σας χρήστη (π.χ. `admin` / `admin`).

3.  **Δημιουργήστε το Pipeline Job:**
    *   Στο dashboard, πηγαίνετε "New Item".
    *   Δώστε ένα όνομα (π.χ. `devops-pets-pipeline`).
    *   Επιλέξτε "Pipeline" και πατήστε "OK".
    *   Στη σελίδα ρυθμίσεων, κατεβείτε στο "Pipeline" section.
    *   Επιλέξτε **Definition:** `Pipeline script from SCM`.
    *   Επιλέξτε **SCM:** `Git`.
    *   Στο **Repository URL**, βάλτε τη διεύθυνση του Git repository.
    *   Πατήστε **Save**.
    *   Ίσως χρειαστεί ρύθμιση στα tools για Maven 3.9.5.
    
Το pipeline σας είναι έτοιμο. Χάρη στη μόνιμη αποθήκευση, **δεν θα χρειαστεί να ξανακάνετε ποτέ αυτή τη διαδικασία**. 