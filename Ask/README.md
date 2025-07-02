# Ask - Spring Boot Backend 

## Επισκόπηση
Το Ask είναι το backend του DevPets, υλοποιημένο με Spring Boot 3.x (Java 17). Παρέχει RESTful APIs για διαχείριση χρηστών, ζώων, αιτημάτων υιοθεσίας και email notifications.

## Τεχνολογίες
- **Spring Boot 3.x**
- **Java 17**
- **PostgreSQL** (JPA/Hibernate)
- **JWT** (Authentication)
- **Maven** (build tool)
- **MailHog** (email testing)

## Δομή Project
```
Ask/
├── src/main/java/com/example/Ask/
│   ├── config/         # Ρυθμίσεις (Security, JWT, AppConfig)
│   ├── Controllers/    # REST API endpoints (Auth, User, Animal, Request, κλπ)
│   ├── Entities/       # Database entities (User, Role, Animal, Request, Gender)
│   ├── Repositories/   # Data access layer (User, Role, Animal, Request)
│   └── Service/        # Business logic (User, Animal, Request, Email)
├── src/main/resources/
│   ├── application.properties  # Ρυθμίσεις DB, JWT, email
│   └── templates/             # Thymeleaf templates (login, error, animal, κλπ)
└── pom.xml            # Maven config
```

## Κύρια Χαρακτηριστικά
- JWT authentication & role-based access (ADMIN, DOCTOR, CITIZEN, SHELTER)
- Email verification για νέους χρήστες
- CRUD για ζώα & αιτήματα υιοθεσίας
- Ειδοποιήσεις μέσω email (MailHog)

## Βασικά Endpoints (ενδεικτικά)
- `POST /api/auth/signin` - Login
- `POST /api/auth/signup` - Εγγραφή
- `GET /api/animals` - Λίστα ζώων
- `POST /api/animals` - Δημιουργία ζώου
- `GET /api/requests` - Λίστα αιτημάτων υιοθεσίας

## Database Schema (βασικά)
- **Users**: id, username, email, password, roles, verified
- **Roles**: id, name
- **Animals**: id, name, type, age, gender, userId
- **Requests**: id, name, type, age, gender, adminApproved, docApproved

## Ανάπτυξη (Development)
- **Προαπαιτούμενα**: Java 17, Maven, PostgreSQL, MailHog
- **Τοπική εκτέλεση**:
  ```bash
  cd Ask
  ./mvnw clean install
  ./mvnw spring-boot:run
  ```
- **Database**: Δημιούργησε DB 'petdb', ρύθμισε credentials στο application.properties
- **Tests**:
  ```bash
  ./mvnw test
  ./mvnw verify
  ```

## Deployment
- Τρέχει ως Docker container στο Kubernetes (port 8080)
- Όλα τα credentials περνάνε μέσω Kubernetes secrets
- Health check: `/actuator/health`

## Ασφάλεια
- JWT tokens με expiration
- BCrypt password encryption
- CORS config για frontend
- Role-based authorization

## Σημείωση
Για πλήρη αρχιτεκτονική και αυτοματοποίηση, δες το `FULL_PROJECT_OVERVIEW.md` 