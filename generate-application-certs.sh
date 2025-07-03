#!/bin/bash

# Generate self-signed certificates for F-B-END application services
echo "Generating self-signed certificates for F-B-END application..."

# Create certificates directory
mkdir -p certs

# Generate certificates for application services
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/frontend-tls.key -out certs/frontend-tls.crt \
  -subj "/CN=frontend.petsystem46.swedencentral.cloudapp.azure.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/minio-tls.key -out certs/minio-tls.crt \
  -subj "/CN=minio.petsystem46.swedencentral.cloudapp.azure.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/pet-system-tls.key -out certs/pet-system-tls.crt \
  -subj "/CN=petsystem46.swedencentral.cloudapp.azure.com"

echo "Application certificates generated successfully!"
echo "Now creating Kubernetes secrets..."

# Create Kubernetes secrets for application
kubectl create secret tls frontend-tls \
  --key certs/frontend-tls.key --cert certs/frontend-tls.crt \
  -n devops-pets --dry-run=client -o yaml > frontend-tls-secret.yaml

kubectl create secret tls minio-tls \
  --key certs/minio-tls.key --cert certs/minio-tls.crt \
  -n devops-pets --dry-run=client -o yaml > minio-tls-secret.yaml

kubectl create secret tls pet-system-tls \
  --key certs/pet-system-tls.key --cert certs/pet-system-tls.crt \
  -n devops-pets --dry-run=client -o yaml > pet-system-tls-secret.yaml

echo "Application secret YAML files created!"
echo "Apply them with: kubectl apply -f *-tls-secret.yaml" 