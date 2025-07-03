#!/bin/bash

echo "=== F-B-END Application Self-Signed Certificates Deployment ==="
echo "This script will generate self-signed certificates for application services"
echo ""

# Check if we're in the right directory
if [ ! -f "generate-application-certs.sh" ]; then
    echo "Error: Please run this script from the F-B-END directory"
    exit 1
fi

# Make the script executable and run it
chmod +x generate-application-certs.sh
./generate-application-certs.sh

echo ""
echo "=== Applying application certificates to Kubernetes ==="

# Apply the certificate secrets for application only
kubectl apply -f frontend-tls-secret.yaml
kubectl apply -f minio-tls-secret.yaml
kubectl apply -f pet-system-tls-secret.yaml

echo ""
echo "=== Updating Application Ingress resources ==="

# Apply the updated ingress configurations for application only
echo "Applying Minio ingress..."
kubectl apply -f k8s/minio/minio-ingress.yaml

echo "Applying main app ingress..."
kubectl apply -f ingress.yaml

echo ""
echo "=== Verification ==="
echo "Checking application certificate secrets..."
kubectl get secrets -n devops-pets | grep tls

echo ""
echo "Checking application ingress status..."
kubectl get ingress -n devops-pets

echo ""
echo "=== Application Services Available ==="
echo "1. Wait a few minutes for the ingress to update"
echo "2. Test access to application services:"
echo "   - Frontend: https://frontend.petsystem46.swedencentral.cloudapp.azure.com"
echo "   - Minio: https://minio.petsystem46.swedencentral.cloudapp.azure.com"
echo "   - API: https://api.petsystem46.swedencentral.cloudapp.azure.com"
echo ""
echo "Note: You'll see a browser warning about self-signed certificates."
echo "This is normal - click 'Advanced' and 'Proceed' to access the services." 