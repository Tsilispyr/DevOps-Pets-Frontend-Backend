Write-Host "Starting Minikube..."
minikube start

Write-Host "Deploying all services with Ansible..."
cd ansible
ansible-playbook deploy-all.yml -v
cd ..

Write-Host "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all --timeout=180s

Write-Host "Port-forwarding services..."
Start-Process powershell -ArgumentList 'kubectl port-forward svc/frontend 8081:80'
Start-Process powershell -ArgumentList 'kubectl port-forward svc/backend 8080:8080'
# Start-Process powershell -ArgumentList 'kubectl port-forward svc/jenkins 8082:8080'  # Commented out - Jenkins takes too long to start
Start-Process powershell -ArgumentList 'kubectl port-forward svc/mailhog 8025:8025'

Write-Host "All set! Open:"
Write-Host "Frontend:  http://localhost:8081"
Write-Host "Backend:   http://localhost:8080"
Write-Host "Mailhog:   http://localhost:8025"
Write-Host ""
Write-Host "--- Jenkins (Optional) ---"
Write-Host "If you need Jenkins for CI/CD, uncomment the Jenkins line in the script"
Write-Host "Jenkins:   http://localhost:8082 (when enabled)" 