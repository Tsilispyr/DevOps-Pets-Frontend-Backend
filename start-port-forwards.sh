#!/bin/bash

# Script to start port forwarding for Devpets-main services
# This allows the F-B-END services to connect to PostgreSQL and MailHog

echo "Starting port forwarding for Devpets-main services..."

# Start port forwarding for PostgreSQL
echo "Starting PostgreSQL port forward (5432:5432)..."
kubectl port-forward service/postgres 5432:5432 &
POSTGRES_PID=$!

# Start port forwarding for MailHog
echo "Starting MailHog port forward (8025:8025)..."
kubectl port-forward service/mailhog 8025:8025 &
MAILHOG_PID=$!

# Start port forwarding for MailHog SMTP
echo "Starting MailHog SMTP port forward (1025:1025)..."
kubectl port-forward service/mailhog 1025:1025 &
MAILHOG_SMTP_PID=$!

echo "Port forwarding started!"
echo "PostgreSQL: localhost:5432"
echo "MailHog UI: http://localhost:8025"
echo "MailHog SMTP: localhost:1025"
echo ""
echo "Press Ctrl+C to stop port forwarding"

# Wait for user to stop
trap "echo 'Stopping port forwarding...'; kill $POSTGRES_PID $MAILHOG_PID $MAILHOG_SMTP_PID; exit" INT
wait 