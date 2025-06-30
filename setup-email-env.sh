#!/bin/bash

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERR!]${NC} $1"
}

echo "=========================================="
echo "  Email Service Setup (Environment Variables)"
echo "=========================================="
echo ""

print_status "This script will help you configure Gmail SMTP using environment variables (more secure)."
echo ""

# Check if application.properties exists
if [ ! -f "Ask/src/main/resources/application.properties" ]; then
    print_error "application.properties not found!"
    exit 1
fi

print_warning "IMPORTANT: You need to create a Gmail App Password first!"
echo ""
echo "Steps to create Gmail App Password:"
echo "1. Go to https://myaccount.google.com/apppasswords"
echo "2. Sign in with your Gmail account"
echo "3. Select 'Mail' and 'Other (Custom name)'"
echo "4. Enter a name like 'Pet Adoption System'"
echo "5. Click 'Generate'"
echo "6. Copy the 16-character password (without spaces)"
echo ""

read -p "Enter your Gmail address: " GMAIL_ADDRESS
read -s -p "Enter your Gmail App Password (16 characters): " GMAIL_PASSWORD
echo ""

# Validate inputs
if [[ -z "$GMAIL_ADDRESS" || -z "$GMAIL_PASSWORD" ]]; then
    print_error "Both Gmail address and App Password are required!"
    exit 1
fi

if [[ ! "$GMAIL_ADDRESS" =~ ^[a-zA-Z0-9._%+-]+@gmail\.com$ ]]; then
    print_error "Please enter a valid Gmail address!"
    exit 1
fi

if [[ ${#GMAIL_PASSWORD} -ne 16 ]]; then
    print_warning "App Password should be 16 characters. Please check if you copied it correctly."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Updating application.properties to use environment variables..."

# Create backup
cp "Ask/src/main/resources/application.properties" "Ask/src/main/resources/application.properties.backup"

# Update the email configuration to use environment variables
sed -i.bak "s/spring.mail.username=.*/spring.mail.username=\${GMAIL_USER}/" "Ask/src/main/resources/application.properties"
sed -i.bak "s/spring.mail.password=.*/spring.mail.password=\${GMAIL_PASS}/" "Ask/src/main/resources/application.properties"

# Remove backup files created by sed
rm -f "Ask/src/main/resources/application.properties.bak"

print_success "application.properties updated to use environment variables!"
echo ""

# Create environment file
print_status "Creating .env file for environment variables..."
cat > .env << EOF
# Gmail SMTP Configuration
GMAIL_USER=$GMAIL_ADDRESS
GMAIL_PASS=$GMAIL_PASSWORD
EOF

print_success ".env file created successfully!"
echo ""

print_status "Configuration details:"
echo "- SMTP Host: smtp.gmail.com"
echo "- SMTP Port: 587"
echo "- Username: \$GMAIL_USER (environment variable)"
echo "- Password: \$GMAIL_PASS (environment variable)"
echo "- Authentication: Enabled"
echo "- TLS: Enabled"
echo ""

print_warning "Security Note:"
echo "- Credentials are stored in .env file (not in application.properties)"
echo "- Add .env to your .gitignore to keep credentials secure"
echo "- Backup created: application.properties.backup"
echo ""

print_status "To run your application with environment variables:"
echo ""
echo "Option 1: Source the .env file and run:"
echo "  source .env && ./mvnw spring-boot:run"
echo ""
echo "Option 2: Export variables manually:"
echo "  export GMAIL_USER=\"$GMAIL_ADDRESS\""
echo "  export GMAIL_PASS=\"$GMAIL_PASSWORD\""
echo "  ./mvnw spring-boot:run"
echo ""
echo "Option 3: Use the run-with-email.sh script (created below)"
echo ""

# Create a convenient run script
print_status "Creating run-with-email.sh script..."
cat > run-with-email.sh << 'EOF'
#!/bin/bash
if [ -f .env ]; then
    source .env
    echo "Starting application with email configuration..."
    ./mvnw spring-boot:run
else
    echo "Error: .env file not found!"
    echo "Please run setup-email-env.sh first."
    exit 1
fi
EOF

chmod +x run-with-email.sh
print_success "run-with-email.sh script created!"

print_status "To test the email service:"
echo "1. Run: ./run-with-email.sh"
echo "2. Register a new user with a real email address"
echo "3. Check if you receive the verification email"
echo ""

print_success "Email service setup complete!" 