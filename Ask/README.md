# Ask - Spring Boot Backend Application

## Overview

Ask is a Spring Boot 3.x backend application that provides RESTful APIs for the pet adoption management system. It handles user authentication, animal management, adoption requests, and email notifications.

## Technology Stack

- **Framework**: Spring Boot 3.x
- **Java Version**: 17
- **Database**: PostgreSQL with JPA/Hibernate
- **Authentication**: JWT (JSON Web Tokens)
- **Build Tool**: Maven
- **Email Service**: Spring Mail with MailHog integration

## Project Structure

```
Ask/
├── src/main/java/com/example/Ask/
│   ├── AskApplication.java          # Main application class
│   ├── config/                      # Configuration classes
│   │   ├── AppConfig.java           # Application configuration
│   │   ├── SecurityConfig.java      # Spring Security configuration
│   │   ├── JwtUtil.java             # JWT utility methods
│   │   ├── AuthTokenFilter.java     # JWT authentication filter
│   │   ├── AuthEntryPointJwt.java   # Authentication entry point
│   │   └── JwtAuthenticationFilter.java # JWT filter implementation
│   ├── Controllers/                 # REST API controllers
│   │   ├── AuthController.java      # Authentication endpoints
│   │   ├── UserController.java      # User management
│   │   ├── AnimalController.java    # Animal CRUD operations
│   │   ├── RequestController.java   # Adoption requests
│   │   ├── AdoptionController.java  # Adoption management
│   │   ├── HomeController.java      # Home page controller
│   │   └── MyErrorController.java   # Error handling
│   ├── Entities/                    # Database entities
│   │   ├── User.java                # User entity
│   │   ├── Role.java                # User roles
│   │   ├── Animal.java              # Animal entity
│   │   ├── Request.java             # Adoption request entity
│   │   └── Gender.java              # Gender enum
│   ├── Repositories/                # Data access layer
│   │   ├── UserRepository.java      # User data access
│   │   ├── RoleRepository.java      # Role data access
│   │   ├── AnimalRepository.java    # Animal data access
│   │   └── RequestRepository.java   # Request data access
│   └── Service/                     # Business logic layer
│       ├── UserService.java         # User business logic
│       ├── AnimalService.java       # Animal business logic
│       ├── RequestService.java      # Request business logic
│       ├── EmailService.java        # Email functionality
│       └── InitialService.java      # Initialization service
├── src/main/resources/
│   ├── application.properties       # Application configuration
│   ├── static/                      # Static resources
│   │   ├── css/                     # CSS files
│   │   └── js/                      # JavaScript files
│   └── templates/                   # Thymeleaf templates
│       ├── auth/                    # Authentication pages
│       ├── Animal/                  # Animal management pages
│       ├── error/                   # Error pages
│       └── page_layout/             # Layout templates
└── pom.xml                          # Maven configuration
```

## Key Features

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (ADMIN, DOCTOR, CITIZEN, SHELTER)
- Email verification for new users
- Password encryption with BCrypt

### User Management
- User registration and login
- Profile management
- Role assignment and management
- Email verification system

### Animal Management
- CRUD operations for animals
- Animal categorization by type and gender
- User-specific animal listings
- Adoption status tracking

### Adoption System
- Adoption request submission
- Request approval workflow
- Admin and doctor approval process
- Request status tracking

### Email Notifications
- Welcome emails for new users
- Email verification links
- Adoption request notifications
- Status update notifications

## API Endpoints

### Authentication
- `POST /api/auth/signin` - User login
- `POST /api/auth/signup` - User registration
- `POST /api/auth/verify-email` - Email verification

### Users
- `GET /api/users` - Get all users (admin only)
- `GET /api/users/{id}` - Get user by ID
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user

### Animals
- `GET /api/animals` - Get all animals
- `GET /api/animals/{id}` - Get animal by ID
- `POST /api/animals` - Create new animal
- `PUT /api/animals/{id}` - Update animal
- `DELETE /api/animals/{id}` - Delete animal

### Requests
- `GET /api/requests` - Get all requests
- `GET /api/requests/{id}` - Get request by ID
- `POST /api/requests` - Create new request
- `PUT /api/requests/{id}` - Update request

## Database Schema

### Users Table
- id (Primary Key)
- username (Unique)
- email (Unique)
- password (Encrypted)
- emailVerified
- createdAt
- lastLogin
- verificationToken
- verificationTokenExpiry

### Roles Table
- id (Primary Key)
- name (ADMIN, DOCTOR, CITIZEN, SHELTER)

### Animals Table
- id (Primary Key)
- name
- type
- age
- gender
- req (requirements)
- userId (Foreign Key to Users)

### Requests Table
- id (Primary Key)
- name
- type
- age
- gender
- adminApproved
- docApproved

## Configuration

### Application Properties
- Database connection settings
- JWT secret and expiration
- Email server configuration
- Server port and context path

### Security Configuration
- CORS settings
- JWT filter configuration
- Role-based access control
- Password encoder configuration

## Development

### Prerequisites
- Java 17 or higher
- Maven 3.6+
- PostgreSQL database
- MailHog for email testing

### Running Locally
```bash
# Navigate to Ask directory
cd Ask

# Install dependencies
./mvnw clean install

# Run application
./mvnw spring-boot:run
```

### Database Setup
1. Create PostgreSQL database named 'petdb'
2. Update application.properties with database credentials
3. Application will auto-create tables on startup

### Testing
```bash
# Run unit tests
./mvnw test

# Run integration tests
./mvnw verify
```

## Deployment

The application is deployed as a Docker container in Kubernetes:
- Base image: openjdk:17-jre-slim
- Port: 8080
- Health checks: /actuator/health
- Environment variables for database connection

## Monitoring

- Health check endpoint: `/actuator/health`
- Application metrics via Spring Boot Actuator
- Logging with SLF4J and Logback
- Database connection monitoring

## Security Considerations

- JWT tokens with expiration
- Password encryption with BCrypt
- CORS configuration for frontend access
- Role-based authorization
- Input validation and sanitization
- SQL injection prevention via JPA 