# Frontend - Vue.js Application

## Overview

The frontend is a modern Vue.js 3 application that provides the user interface for the pet adoption management system. It features a responsive design, real-time data management, and seamless integration with the Spring Boot backend API.

## Technology Stack

- **Framework**: Vue.js 3 with Composition API
- **Build Tool**: Vite
- **State Management**: Pinia
- **Routing**: Vue Router 4
- **UI Framework**: Bootstrap 5
- **HTTP Client**: Axios
- **Styling**: CSS3 with Bootstrap components
- **Package Manager**: NPM

## Project Structure

```
frontend/
├── public/                     # Static assets
│   └── vite.svg               # Vite logo
├── src/                       # Source code
│   ├── assets/                # Static assets
│   │   └── vue.svg            # Vue logo
│   ├── components/            # Reusable Vue components
│   │   ├── Navbar.vue         # Navigation bar component
│   │   ├── HelloWorld.vue     # Welcome component
│   │   ├── AnimalList.vue     # Animal listing component
│   │   ├── UserList.vue       # User management component
│   │   ├── UserForm.vue       # User form component
│   │   ├── RequestList.vue    # Request listing component
│   │   └── AdoptionRequestList.vue # Adoption requests component
│   ├── views/                 # Page components
│   │   ├── Home.vue           # Home page
│   │   ├── Login.vue          # Login page
│   │   ├── Register.vue       # Registration page
│   │   ├── Animals.vue        # Animals listing page
│   │   ├── AddAnimal.vue      # Add animal page
│   │   ├── AnimalDetail.vue   # Animal details page
│   │   ├── Requests.vue       # Requests page
│   │   ├── RequestDetail.vue  # Request details page
│   │   ├── Users.vue          # User management page
│   │   ├── Admin.vue          # Admin dashboard
│   │   ├── Citizen.vue        # Citizen dashboard
│   │   ├── Doctor.vue         # Doctor dashboard
│   │   ├── Shelter.vue        # Shelter dashboard
│   │   └── VerifyEmail.vue    # Email verification page
│   ├── stores/                # Pinia state management
│   │   ├── auth.js            # Authentication store
│   │   └── application.js     # Application state store
│   ├── composables/           # Vue 3 composables
│   │   └── useRemoteData.js   # Data fetching composable
│   ├── App.vue                # Root component
│   ├── main.js                # Application entry point
│   ├── router.js              # Vue Router configuration
│   ├── api.js                 # API client configuration
│   └── style.css              # Global styles
├── index.html                 # HTML template
├── package.json               # NPM dependencies
├── vite.config.js             # Vite configuration
└── README.md                  # This documentation
```

## Key Features

### User Interface
- Responsive design that works on desktop and mobile
- Modern, clean interface using Bootstrap 5
- Intuitive navigation with role-based menus
- Real-time data updates
- Form validation and error handling

### Authentication System
- JWT token-based authentication
- Automatic token refresh
- Role-based access control
- Protected routes
- Login/logout functionality

### Animal Management
- Browse available animals
- Add new animals (Shelter role)
- View animal details
- Search and filter animals
- Animal status tracking

### User Management
- User registration and login
- Profile management
- Role-based dashboards
- Admin user management
- Email verification

### Adoption System
- Submit adoption requests
- Track request status
- Admin and doctor approval workflow
- Request history

### Dashboard Views
- **Admin Dashboard**: User management, system overview
- **Citizen Dashboard**: Browse animals, submit requests
- **Doctor Dashboard**: Review and approve requests
- **Shelter Dashboard**: Manage animals, view requests

## Component Architecture

### Core Components

#### Navbar.vue
- Responsive navigation bar
- Role-based menu items
- User authentication status
- Logout functionality

#### AnimalList.vue
- Displays list of animals
- Search and filter functionality
- Pagination support
- Action buttons for each animal

#### UserForm.vue
- Reusable form for user data
- Validation and error handling
- Support for create and edit modes

### Page Components

#### Home.vue
- Welcome page with system overview
- Quick access to main features
- Statistics and information

#### Login.vue / Register.vue
- User authentication forms
- Form validation
- Error message display
- Redirect after successful authentication

#### Animals.vue
- Main animals listing page
- Integration with AnimalList component
- Add animal functionality for shelters

#### Admin.vue
- Administrative dashboard
- User management interface
- System statistics
- Quick actions

## State Management (Pinia)

### Auth Store (auth.js)
```javascript
// Manages authentication state
- user: Current user information
- token: JWT authentication token
- isAuthenticated: Authentication status
- login(): User login
- logout(): User logout
- register(): User registration
```

### Application Store (application.js)
```javascript
// Manages application-wide state
- animals: Animal data
- requests: Request data
- users: User data
- loading: Loading states
- errors: Error handling
```

## API Integration

### API Client (api.js)
- Axios-based HTTP client
- Automatic JWT token inclusion
- Error handling and interceptors
- Base URL configuration

### Data Fetching (useRemoteData.js)
- Vue 3 composable for data fetching
- Loading and error states
- Automatic data refresh
- Caching support

## Routing

### Route Configuration
- Protected routes with authentication guards
- Role-based route access
- Lazy loading for better performance
- Nested routes for complex pages

### Route Guards
- Authentication verification
- Role-based access control
- Redirect handling for unauthorized access

## Styling

### CSS Architecture
- Bootstrap 5 for responsive design
- Custom CSS for specific components
- CSS variables for theming
- Mobile-first approach

### Design System
- Consistent color scheme
- Typography hierarchy
- Component spacing
- Interactive states (hover, focus, active)

## Development

### Prerequisites
- Node.js 16+ and NPM
- Modern web browser
- Backend API running

### Local Development
```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Environment Configuration
- API base URL configuration
- Development vs production settings
- Environment variables support

## Build and Deployment

### Build Process
1. **Development**: Vite dev server with hot reload
2. **Production**: Optimized build with minification
3. **Static Assets**: Optimized images and fonts
4. **Bundle Analysis**: Size optimization

### Deployment
- Static file hosting
- Nginx configuration for SPA routing
- CDN integration for assets
- Environment-specific builds

## Performance Optimization

### Code Splitting
- Route-based code splitting
- Component lazy loading
- Vendor chunk separation

### Asset Optimization
- Image compression
- Font loading optimization
- CSS and JS minification
- Gzip compression

### Caching Strategy
- Browser caching for static assets
- API response caching
- Service worker for offline support

## Testing

### Unit Testing
- Component testing with Vue Test Utils
- Store testing with Pinia
- Utility function testing

### Integration Testing
- API integration testing
- User flow testing
- Cross-browser compatibility

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Accessibility

- ARIA labels and roles
- Keyboard navigation support
- Screen reader compatibility
- Color contrast compliance
- Focus management

## Security

- XSS prevention
- CSRF protection
- Secure token storage
- Input sanitization
- HTTPS enforcement
