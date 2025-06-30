# Email Service Setup Guide

This guide explains how to configure the Pet Adoption System to send real emails instead of using MailHog for testing.

## Prerequisites

1. **Gmail Account with 2-Step Verification Enabled**
   - You need a Gmail account
   - 2-Step Verification must be enabled on your Google account
   - This is required to generate App Passwords

## Option 1: Direct Configuration (Simple)

### Step 1: Create Gmail App Password

1. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
2. Sign in with your Gmail account
3. Select "Mail" and "Other (Custom name)"
4. Enter a name like "Pet Adoption System"
5. Click "Generate"
6. Copy the 16-character password (without spaces)

### Step 2: Run Setup Script

```bash
cd F-B-END
chmod +x setup-email.sh
./setup-email.sh
```

The script will:
- Ask for your Gmail address and App Password
- Update `application.properties` with your credentials
- Create a backup of the original configuration

### Step 3: Test the Email Service

1. Start your Spring Boot application
2. Register a new user with a real email address
3. Check if you receive the verification email

## Option 2: Environment Variables (Recommended for Security)

### Step 1: Create Gmail App Password

Same as Option 1.

### Step 2: Run Environment Setup Script

```bash
cd F-B-END
chmod +x setup-email-env.sh
./setup-email-env.sh
```

The script will:
- Ask for your Gmail address and App Password
- Update `application.properties` to use environment variables
- Create a `.env` file with your credentials
- Create a convenient `run-with-email.sh` script

### Step 3: Run Application with Email Support

```bash
./run-with-email.sh
```

Or manually:
```bash
source .env
./mvnw spring-boot:run
```

## Configuration Details

### SMTP Settings (Gmail)
- **Host:** smtp.gmail.com
- **Port:** 587
- **Authentication:** Enabled
- **TLS:** Enabled
- **Connection Timeout:** 5000ms
- **Read Timeout:** 5000ms
- **Write Timeout:** 5000ms

### Email Templates

The system includes several email templates:
- **Verification Email:** Sent when users register
- **Welcome Email:** Sent after email verification
- **Login Notification:** Sent on new login (if enabled)

## Security Notes

### Option 1 (Direct Configuration)
- ✅ Simple to set up
- ❌ Credentials stored in `application.properties`
- ❌ Credentials visible in source code

### Option 2 (Environment Variables)
- ✅ More secure
- ✅ Credentials not in source code
- ✅ `.env` file is ignored by Git
- ❌ Slightly more complex setup

## Troubleshooting

### Common Issues

1. **"Authentication failed"**
   - Ensure 2-Step Verification is enabled
   - Verify App Password is correct (16 characters)
   - Check if Gmail account is not locked

2. **"Connection timeout"**
   - Check internet connection
   - Verify firewall settings
   - Try different network

3. **"Invalid username or password"**
   - Use App Password, not your regular Gmail password
   - Ensure no extra spaces in the password

### Testing Email Service

You can test the email service by:
1. Starting the application
2. Registering a new user
3. Checking the inbox (and spam folder) for verification email

### Switching Back to MailHog

If you want to switch back to MailHog for testing:

```bash
# Restore backup
cp Ask/src/main/resources/application.properties.backup Ask/src/main/resources/application.properties

# Or manually update application.properties:
spring.mail.host=mailhog
spring.mail.port=1025
spring.mail.username=
spring.mail.password=
spring.mail.properties.mail.smtp.auth=false
spring.mail.properties.mail.smtp.starttls.enable=false
```

## Alternative Email Providers

You can use other SMTP providers by updating the configuration:

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

## Files Modified

- `Ask/src/main/resources/application.properties` - Email configuration
- `.gitignore` - Added entries for email credentials
- `setup-email.sh` - Setup script for direct configuration
- `setup-email-env.sh` - Setup script for environment variables
- `run-with-email.sh` - Convenient run script (created by setup)
- `.env` - Environment variables file (created by setup)

## Support

If you encounter issues:
1. Check the application logs for detailed error messages
2. Verify your Gmail App Password is correct
3. Ensure 2-Step Verification is enabled
4. Check if your Gmail account allows "less secure app access" (if applicable) 