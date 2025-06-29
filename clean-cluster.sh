#!/bin/bash

echo "Cleaning Kubernetes cluster..."

# Check if kubeconfig exists
if [ ! -f "jenkins-kubeconfig" ]; then
    echo "Error: jenkins-kubeconfig file not found!"
    echo "Please ensure you have the kubeconfig file in the current directory."
    exit 1
fi

export KUBECONFIG=$PWD/jenkins-kubeconfig

echo "Deleting existing deployments..."
kubectl delete deployment backend --ignore-not-found=true
kubectl delete deployment frontend --ignore-not-found=true

echo "Deleting existing services..."
kubectl delete service backend --ignore-not-found=true
kubectl delete service frontend --ignore-not-found=true

echo "Deleting any orphaned pods..."
kubectl delete pods -l app=backend --ignore-not-found=true
kubectl delete pods -l app=frontend --ignore-not-found=true

echo "Cleaning old Docker images..."
docker images | grep devops-pets | tail -n +6 | awk '{print $3}' | xargs -r docker rmi -f || true

echo "Cluster cleanup completed!"
echo "Current cluster status:"
kubectl get all 