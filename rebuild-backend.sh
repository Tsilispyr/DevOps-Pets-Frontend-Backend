#!/bin/bash

echo "Rebuilding and restarting backend..."

# Delete the backend pod to force a restart
kubectl delete pod -l app=backend-deployment

# Wait for the new pod to be ready
echo "Waiting for backend pod to be ready..."
kubectl wait --for=condition=ready pod -l app=backend-deployment --timeout=120s

echo "Backend restart completed!" 