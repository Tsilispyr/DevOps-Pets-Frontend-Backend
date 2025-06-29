<<<<<<< HEAD
# DevOps
=======
# Exercise_Ask_Kat
Exercise for Distributed Systems 2024-2025
User Manual

## Authentication System
This application uses JWT (JSON Web Token) based authentication. Users can register and login through the application's built-in authentication system.

## Default Users

User Username: user Password: user

Admin Username: admin Password: admin

Doctor Username: Doctor Password: Doctor

Shelter Username: shelter Password: shelter

## User Roles and Permissions

### User
The user after login can view the Animal tab where animal entries are, he can choose to view a single or all animals and request to adopt a single or multiple animals by pressing the Request button.

### Shelter
The shelter user can view all available animals by going to the Animal tab from the header, there he can approve adoption requests or he can delete an animal. Also he has access to the Request tab where he can place requests for new animal adoption entries and wait for Doctor and admin approval to make eligible for adoption.

### Doctor 
The Doctor user can view all animals like shelter and user can, he also has access to the Request tab where he is responsible for the approval of the animals requests.

### Admin
The Admin has access to all available actions that Shelter and Doctor have, and also he has access to the user tab where he can view all users registered in the system and can delete users and change user information, add or remove roles from users. Lastly he has the responsibility for approving animals requests.

## System Architecture
- **Frontend**: Vue.js application with JWT authentication
- **Backend**: Spring Boot REST API with JWT security
- **Database**: PostgreSQL
- **Email**: MailHog for email testing
- **CI/CD**: Jenkins
- **Containerization**: Docker & Kubernetes

## Access URLs
- Frontend: http://localhost:8081
- Backend API: http://localhost:8080
- Jenkins: http://localhost:8082
- MailHog: http://localhost:8025

## Quick Start

### For Linux/Mac:
```bash
chmod +x devops-pets-up.sh
./devops-pets-up.sh
```

### For Windows:
```powershell
.\devops-pets-up.ps1
```

For detailed installation instructions, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).



 
>>>>>>> 9531d7d (Front and Back from Me)
