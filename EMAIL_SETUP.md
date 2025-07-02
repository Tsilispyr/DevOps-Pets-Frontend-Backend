# Οδηγός Ρύθμισης Υπηρεσίας Email

Αυτός ο οδηγός εξηγεί πώς να ρυθμίσετε το Σύστημα Υιοθεσίας Κατοικιδίων ώστε να στέλνει πραγματικά emails αντί για χρήση του MailHog για δοκιμές.

## Προαπαιτούμενα

1. **Λογαριασμός Gmail με ενεργοποιημένο 2-Step Verification**
   - Απαιτείται λογαριασμός Gmail
   - Πρέπει να είναι ενεργοποιημένο το 2-Step Verification
   - Αυτό απαιτείται για τη δημιουργία App Passwords

## Επιλογή 1: Άμεση Ρύθμιση (Απλή)

### Βήμα 1: Δημιουργία App Password στο Gmail

1. Μεταβείτε στη σελίδα [Google App Passwords](https://myaccount.google.com/apppasswords)
2. Συνδεθείτε με τον λογαριασμό σας
3. Επιλέξτε "Mail" και "Other (Custom name)"
4. Δώστε ένα όνομα π.χ. "Pet Adoption System"
5. Πατήστε "Generate"
6. Αντιγράψτε τον 16-ψήφιο κωδικό (χωρίς κενά)

### Βήμα 2: Εκτέλεση Script Ρύθμισης

```bash
cd F-B-END
chmod +x setup-email.sh
./setup-email.sh
```

Το script θα:
- Ζητήσει το Gmail και το App Password
- Ενημερώσει το `application.properties` με τα στοιχεία σας
- Δημιουργήσει backup του αρχικού αρχείου

### Βήμα 3: Τεστ Υπηρεσίας Email

1. Εκκινήστε το Spring Boot application
2. Κάντε εγγραφή νέου χρήστη με πραγματικό email
3. Ελέγξτε αν λάβατε email επιβεβαίωσης

## Επιλογή 2: Μεταβλητές Περιβάλλοντος (Συνιστάται για Ασφάλεια)

### Βήμα 1: Δημιουργία App Password στο Gmail
Όπως και στην Επιλογή 1.

### Βήμα 2: Εκτέλεση Script Ρύθμισης Περιβάλλοντος

```bash
cd F-B-END
chmod +x setup-email-env.sh
./setup-email-env.sh
```

Το script θα:
- Ζητήσει το Gmail και το App Password
- Ενημερώσει το `application.properties` ώστε να χρησιμοποιεί μεταβλητές περιβάλλοντος
- Δημιουργήσει αρχείο `.env` με τα στοιχεία σας
- Δημιουργήσει script `run-with-email.sh`

### Βήμα 3: Εκκίνηση Εφαρμογής με Email

```bash
./run-with-email.sh
```

Ή χειροκίνητα:
```bash
source .env
./mvnw spring-boot:run
```

## Ρυθμίσεις SMTP (Gmail)
- **Host:** smtp.gmail.com
- **Port:** 587
- **Authentication:** Ενεργό
- **TLS:** Ενεργό
- **Connection Timeout:** 5000ms
- **Read Timeout:** 5000ms
- **Write Timeout:** 5000ms

## Templates Email
- **Email Επιβεβαίωσης**: Κατά την εγγραφή
- **Email Καλωσορίσματος**: Μετά την επιβεβαίωση
- **Ειδοποίηση Εισόδου**: Σε νέα είσοδο (αν είναι ενεργό)

## Σημειώσεις Ασφαλείας

### Επιλογή 1 (Άμεση Ρύθμιση)
- ✅ Απλή ρύθμιση
- ❌ Τα credentials αποθηκεύονται στο `application.properties`
- ❌ Τα credentials φαίνονται στον κώδικα

### Επιλογή 2 (Μεταβλητές Περιβάλλοντος)
- ✅ Πιο ασφαλές
- ✅ Τα credentials δεν είναι στον κώδικα
- ✅ Το `.env` αγνοείται από το Git
- ❌ Λίγο πιο σύνθετη ρύθμιση

## Επίλυση Προβλημάτων

### Συχνά Προβλήματα

1. **"Authentication failed"**
   - Βεβαιωθείτε ότι το 2-Step Verification είναι ενεργό
   - Ελέγξτε το App Password (16 χαρακτήρες)
   - Ελέγξτε αν ο λογαριασμός Gmail δεν είναι κλειδωμένος

2. **"Connection timeout"**
   - Ελέγξτε τη σύνδεση στο internet
   - Ελέγξτε τα firewall settings
   - Δοκιμάστε άλλο δίκτυο

3. **"Invalid username or password"**
   - Χρησιμοποιήστε App Password, όχι το κανονικό password
   - Ελέγξτε για κενά/λάθη στον κωδικό

### Τεστ Υπηρεσίας Email
1. Εκκινήστε την εφαρμογή
2. Κάντε εγγραφή νέου χρήστη
3. Ελέγξτε το inbox (και spam)

### Επιστροφή σε MailHog (Test Mode)

```bash
# Επαναφορά backup
cp Ask/src/main/resources/application.properties.backup Ask/src/main/resources/application.properties

# Ή χειροκίνητα:
spring.mail.host=mailhog
spring.mail.port=1025
spring.mail.username=
spring.mail.password=
spring.mail.properties.mail.smtp.auth=false
spring.mail.properties.mail.smtp.starttls.enable=false
```

## Εναλλακτικοί Πάροχοι SMTP

### Outlook/Hotmail
```properties
spring.mail.host=smtp-mail.outlook.com
spring.mail.port=587
spring.mail.username=your-email@outlook.com
spring.mail.password=your-app-password
```

### SendGrid
```properties
spring.mail.host=smtp.sendgrid.net
spring.mail.port=587
spring.mail.username=apikey
spring.mail.password=your-sendgrid-api-key
```

### Mailgun
```properties
spring.mail.host=smtp.mailgun.org
spring.mail.port=587
spring.mail.username=your-mailgun-username
spring.mail.password=your-mailgun-password
```

## Αρχεία που Επηρεάζονται

- `Ask/src/main/resources/application.properties` - Ρύθμιση email
- `.gitignore` - Αγνοεί credentials email
- `setup-email.sh` - Script άμεσης ρύθμισης
- `setup-email-env.sh` - Script ρύθμισης περιβάλλοντος
- `run-with-email.sh` - Script εκκίνησης (δημιουργείται από setup)
- `.env` - Αρχείο μεταβλητών περιβάλλοντος (δημιουργείται από setup)

## Υποστήριξη

Αν αντιμετωπίσετε προβλήματα:
1. Ελέγξτε τα logs της εφαρμογής για λεπτομέρειες
2. Επαληθεύστε το App Password
3. Βεβαιωθείτε ότι το 2-Step Verification είναι ενεργό
4. Ελέγξτε αν ο λογαριασμός Gmail επιτρέπει "λιγότερο ασφαλείς εφαρμογές" (αν χρειάζεται)

---

**Cloud/HTTPS Σημείωση:**
Για παραγωγική χρήση σε cloud περιβάλλον, προτιμήστε πάντα μεταβλητές περιβάλλοντος και ασφαλή αποθήκευση credentials (π.χ. Kubernetes Secrets). 