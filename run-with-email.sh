#!/bin/bash
if [ -f .env ]; then
    source .env
    echo "Starting application with email configuration..."
    cd Ask
    ./mvnw spring-boot:run
else
    echo "Error: .env file not found!"
    echo "Please run setup-email-env.sh first."
    exit 1
fi
