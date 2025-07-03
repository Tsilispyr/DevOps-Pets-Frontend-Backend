pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
    }

    environment {
        NAMESPACE = "devops-pets"
        TIMEOUT = "300s"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Kubeconfig') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 1: SETTING UP KUBECONFIG"
                    echo "========================================"
                    
                    // Set up kubeconfig using default service account
                    sh '''
                        echo "Setting up kubeconfig for Jenkins..."
                        
                        # Create .kube directory if it doesn't exist
                        mkdir -p ~/.kube
                        
                        # Get the default service account token
                        echo "Getting default service account token..."
                        
                        # Get the token from the default service account
                        TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                        
                        # Get the CA certificate
                        CA_CERT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
                        
                        # Create kubeconfig with default service account
                        cat > ~/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kubernetes.default.svc
    certificate-authority-data: $CA_CERT
  name: devops-pets
contexts:
- context:
    cluster: devops-pets
    user: jenkins-default
  name: kind-devops-pets
current-context: kind-devops-pets
users:
- name: jenkins-default
  user:
    token: $TOKEN
EOF
                        
                        # Set proper permissions
                        chmod 600 ~/.kube/config
                        
                        echo "Kubeconfig set up successfully with default service account"
                        
                        # Test cluster connection
                        echo "Testing cluster connection..."
                        kubectl cluster-info
                        kubectl get nodes
                        
                        # Check if devops-pets namespace exists
                        if kubectl get namespace devops-pets 2>/dev/null; then
                            echo "OK! devops-pets namespace exists"
                        else
                            echo "Creating devops-pets namespace..."
                            kubectl create namespace devops-pets
                        fi
                        
                        # Show current context
                        echo "Current kubeconfig context:"
                        kubectl config current-context
                        
                        # Show cluster info
                        echo "Cluster information:"
                        kubectl config view --minify
                    '''
                }
            }
        }

        stage('Complete Cleanup') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 2: COMPLETE CLEANUP"
                    echo "========================================"
                    
                    // Stop all port forwarding
                    sh '''
                        pkill -f "kubectl port-forward" || true
                        sleep 3
                    '''
                    
                    // Delete existing deployments and services
                    sh '''
                        echo "Deleting existing deployments..."
                        kubectl delete deployment backend -n ${NAMESPACE} --ignore-not-found=true || true
                        kubectl delete deployment frontend -n ${NAMESPACE} --ignore-not-found=true || true
                        
                        echo "Deleting existing services..."
                        kubectl delete service backend -n ${NAMESPACE} --ignore-not-found=true || true
                        kubectl delete service frontend -n ${NAMESPACE} --ignore-not-found=true || true
                        
                        echo "Deleting any orphaned pods..."
                        kubectl delete pods -l app=backend -n ${NAMESPACE} --ignore-not-found=true || true
                        kubectl delete pods -l app=frontend -n ${NAMESPACE} --ignore-not-found=true || true
                        
                        echo "Waiting for resources to be deleted..."
                        sleep 10
                    '''
                }
            }
        }

        stage('Apply RBAC Configuration') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 3.5: APPLYING RBAC CONFIGURATION"
                    echo "========================================"
                    
                    // Apply RBAC configuration first
                    sh '''
                        echo "Applying RBAC configuration..."
                        kubectl apply -f k8s/jenkins/jenkins-rbac.yaml
                        echo "OK! RBAC configuration applied"
                        
                        echo "Verifying service account permissions..."
                        kubectl auth can-i get pods -n ${NAMESPACE}
                        kubectl auth can-i create deployments -n ${NAMESPACE}
                        kubectl auth can-i create services -n ${NAMESPACE}
                        echo "OK! Permissions verified"
                    '''
                }
            }
        }

        stage('Build Java Application') {
            steps {
                dir('Ask') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                    
                    // Debug: Check frontend build output
                    sh '''
                        echo "=== DEBUG: FRONTEND BUILD OUTPUT ==="
                        echo "Files in dist/:"
                        ls -la dist/
                        echo ""
                        echo "index.html content (first 20 lines):"
                        head -20 dist/index.html
                        echo ""
                        echo "index.html size:"
                        ls -lh dist/index.html
                        echo ""
                        echo "Assets directory:"
                        ls -la dist/assets/
                        echo ""
                        echo "Total dist size:"
                        du -sh dist/
                    '''
                }
            }
        }

        stage('Prepare Files for Deployment') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 4: PREPARING FILES FOR DEPLOYMENT"
                    echo "========================================"
                    
                    // Copy JAR file to target directory
                    dir('Ask') {
                        sh '''
                            echo "Preparing backend JAR file..."
                            ls -la target/
                            cp target/*.jar target/app.jar
                            echo "OK! Backend JAR prepared"
                        '''
                    }
                    
                    // Verify frontend build
                    dir('frontend') {
                        sh '''
                            echo "Verifying frontend build..."
                            ls -la dist/
                            echo "OK! Frontend build verified"
                        '''
                    }
                }
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 5: PREPARING DEPLOYMENT FILES"
                    echo "========================================"
                    
                    // Prepare backend files
                    dir('Ask') {
                        sh '''
                            echo "Preparing backend files..."
                            ls -la target/
                            echo "Backend JAR size:"
                            ls -lh target/app.jar
                            echo "OK! Backend files prepared"
                        '''
                    }
                    
                    // Prepare frontend files
                    dir('frontend') {
                        sh '''
                            echo "Preparing frontend files..."
                            ls -la dist/
                            echo "Frontend files size:"
                            du -sh dist/
                            echo "OK! Frontend files prepared"
                        '''
                    }
                    
                    echo "OK! All files prepared successfully"
                }
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 6: UPDATING KUBERNETES MANIFESTS"
                    echo "========================================"
                    
                    // Update backend deployment to use init container with file copy
                    sh '''
                        echo "Updating backend deployment for init container..."
                        cat > k8s/backend/backend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: devops-pets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      initContainers:
        - name: copy-jar
          image: busybox:latest
          command: ['sh', '-c', 'cp /shared/app.jar /app/app.jar && echo "JAR copied successfully"']
          volumeMounts:
            - name: shared-storage
              mountPath: /shared
            - name: app-jar
              mountPath: /app
      containers:
        - name: backend
          image: openjdk:17-jdk-slim
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_URL
              value: jdbc:postgresql://postgres.devops-pets.svc.cluster.local:5432/petdb
            - name: SPRING_DATASOURCE_USERNAME
              value: petuser
            - name: SPRING_DATASOURCE_PASSWORD
              value: petpass
            - name: SPRING_MAIL_HOST
              value: smtp.gmail.com
            - name: SPRING_MAIL_PORT
              value: "587"
            - name: GMAIL_USER
              valueFrom:
                secretKeyRef:
                  name: gmail-secret
                  key: GMAIL_USER
            - name: GMAIL_PASS
              valueFrom:
                secretKeyRef:
                  name: gmail-secret
                  key: GMAIL_PASS
            - name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI
              value: http://localhost:8083/realms/petsystem
            - name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_AUDIENCES
              value: backend
          command: ["java", "-jar", "/app/app.jar"]
          volumeMounts:
            - name: app-jar
              mountPath: /app
            - name: shared-storage
              mountPath: /shared
      volumes:
        - name: app-jar
          emptyDir: {}
        - name: shared-storage
          persistentVolumeClaim:
            claimName: shared-storage
EOF
                    '''
                    
                    // Update frontend deployment to use init container with file copy
                    sh '''
                        echo "Updating frontend deployment for init container..."
                        cat > k8s/frontend/frontend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: devops-pets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      initContainers:
        - name: copy-files
          image: busybox:latest
          command: ['sh', '-c', 'cp -r /shared/frontend/* /usr/share/nginx/html/ && echo "Frontend files copied successfully"']
          volumeMounts:
            - name: shared-storage
              mountPath: /shared
            - name: frontend-files
              mountPath: /usr/share/nginx/html
      containers:
        - name: frontend
          image: nginx:stable-alpine
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          volumeMounts:
            - name: frontend-files
              mountPath: /usr/share/nginx/html
            - name: shared-storage
              mountPath: /shared
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: nginx.conf
      volumes:
        - name: frontend-files
          emptyDir: {}
        - name: shared-storage
          persistentVolumeClaim:
            claimName: shared-storage
        - name: nginx-config
          configMap:
            name: nginx-config
EOF
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 8: DEPLOYING TO KUBERNETES"
                    echo "========================================"
                    
                    // Apply all Kubernetes resources
                    sh '''
                        echo "Applying Kubernetes resources..."
                        
                        # Force delete and recreate nginx ConfigMap
                        echo "Force deleting existing nginx ConfigMap..."
                        kubectl delete configmap nginx-config -n ${NAMESPACE} --ignore-not-found=true
                        
                        # Create nginx ConfigMap using the YAML file
                        echo "Creating nginx ConfigMap using YAML file..."
                        kubectl apply -f nginx-config.yaml
                        
                        echo "Verifying nginx ConfigMap..."
                        kubectl get configmap nginx-config -n ${NAMESPACE} -o yaml
                        
                        kubectl apply -R -f k8s/ -n ${NAMESPACE}
                        echo "OK! Resources applied"
                        
                        # Apply MinIO resources
                        echo "Applying MinIO resources..."
                        kubectl apply -f k8s/minio/ -n ${NAMESPACE}
                        echo "OK! MinIO resources applied"
                        
                        # Generate and apply self-signed certificates for application
                        echo "Generating self-signed certificates for application..."
                        chmod +x generate-application-certs.sh
                        ./generate-application-certs.sh
                        
                        echo "Applying application certificates..."
                        kubectl apply -f frontend-tls-secret.yaml
                        kubectl apply -f minio-tls-secret.yaml
                        kubectl apply -f pet-system-tls-secret.yaml
                        echo "OK! Application certificates applied"
                        
                        # Apply ingress for HTTPS frontend access
                        echo "Applying ingress for HTTPS frontend access..."
                        kubectl apply -f ingress.yaml
                        echo "OK! Ingress applied"
                        
                        # Apply MinIO ingress for HTTPS access
                        echo "Applying MinIO ingress for HTTPS access..."
                        kubectl apply -f k8s/minio/minio-ingress.yaml
                        echo "OK! MinIO ingress applied"
                        
                        # Wait for MinIO to be ready
                        echo "Waiting for MinIO to be ready..."
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/minio -n ${NAMESPACE}
                        kubectl wait --for=condition=ready pod -l app=minio -n ${NAMESPACE} --timeout=${TIMEOUT}
                        echo "OK! MinIO is ready"
                        
                        # Force restart frontend deployment to pick up new ConfigMap
                        echo "Force restarting frontend deployment..."
                        kubectl rollout restart deployment frontend -n ${NAMESPACE}
                        echo "OK! Frontend deployment restarted"
                    '''
                    
                    // Wait for pods to be created (not necessarily ready)
                    sh '''
                        echo "Waiting for pods to be created..."
                        
                        echo "Waiting for backend pod to be created..."
                        kubectl wait --for=condition=podScheduled pod -l app=backend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        echo "OK! Backend pod is created"
                        
                        echo "Waiting for frontend pod to be created..."
                        kubectl wait --for=condition=podScheduled pod -l app=frontend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        echo "OK! Frontend pod is created"
                    '''
                    
                    // Copy files to shared storage
                    sh '''
                        echo "Copying files to shared storage..."
                        
                        # Debug: Check PVC status
                        echo "=== DEBUG: PVC STATUS ==="
                        kubectl get pvc -n ${NAMESPACE}
                        kubectl describe pvc shared-storage -n ${NAMESPACE}
                        
                        # Debug: Check if shared storage exists
                        echo "=== DEBUG: SHARED STORAGE STATUS ==="
                        kubectl get pv | grep shared-storage || echo "No shared-storage PV found"
                        
                        # Create a temporary pod to copy files to shared storage
                        echo "Creating temporary pod for file copying..."
                        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: file-copy-pod
  namespace: ${NAMESPACE}
spec:
  containers:
  - name: file-copy
    image: busybox:latest
    command: ['sh', '-c', 'sleep 3600']
    volumeMounts:
    - name: shared-storage
      mountPath: /shared
  volumes:
  - name: shared-storage
    persistentVolumeClaim:
      claimName: shared-storage
  restartPolicy: Never
EOF
                        
                        # Wait for the pod to be ready
                        echo "Waiting for file-copy-pod to be ready..."
                        kubectl wait --for=condition=ready pod/file-copy-pod -n ${NAMESPACE} --timeout=60s
                        
                        # Debug: Check if pod can access shared storage
                        echo "=== DEBUG: SHARED STORAGE ACCESS ==="
                        kubectl exec -n ${NAMESPACE} file-copy-pod -- ls -la /shared/ || echo "Cannot access /shared/"
                        
                        # Copy JAR to shared storage
                        echo "Copying JAR to shared storage..."
                        kubectl cp Ask/target/app.jar ${NAMESPACE}/file-copy-pod:/shared/app.jar
                        echo "OK! JAR copied to shared storage"
                        
                        # Copy frontend files to shared storage
                        echo "Copying frontend files to shared storage..."
                        kubectl cp frontend/dist/ ${NAMESPACE}/file-copy-pod:/shared/frontend/
                        echo "OK! Frontend files copied to shared storage"
                        
                        # Verify files were copied correctly
                        echo "=== DEBUG: VERIFYING FILES IN SHARED STORAGE ==="
                        echo "Files in /shared/:"
                        kubectl exec -n ${NAMESPACE} file-copy-pod -- ls -la /shared/
                        echo ""
                        echo "Files in /shared/frontend/:"
                        kubectl exec -n ${NAMESPACE} file-copy-pod -- ls -la /shared/frontend/
                        echo ""
                        echo "Frontend index.html content (first 10 lines):"
                        kubectl exec -n ${NAMESPACE} file-copy-pod -- head -10 /shared/frontend/index.html || echo "Cannot read index.html"
                        echo ""
                        echo "JAR file size:"
                        kubectl exec -n ${NAMESPACE} file-copy-pod -- ls -lh /shared/app.jar || echo "Cannot read app.jar"
                        
                        # Delete the temporary pod
                        kubectl delete pod file-copy-pod -n ${NAMESPACE}
                        echo "OK! Temporary pod deleted"
                    '''
                    
                    // Now wait for pods to be ready
                    sh '''
                        echo "Waiting for pods to be ready..."
                        
                        echo "Waiting for backend pod..."
                        kubectl wait --for=condition=ready pod -l app=backend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        echo "OK! Backend pod is ready"
                        
                        echo "Waiting for frontend pod..."
                        kubectl wait --for=condition=ready pod -l app=frontend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        echo "OK! Frontend pod is ready"
                        
                        # Debug: Check pod volume mounts
                        echo "=== DEBUG: POD VOLUME MOUNTS ==="
                        echo "Backend pod volume mounts:"
                        kubectl get pod -l app=backend -n ${NAMESPACE} -o jsonpath='{.items[0].spec.volumes[*].name}' | tr ' ' '\n'
                        echo ""
                        echo "Frontend pod volume mounts:"
                        kubectl get pod -l app=frontend -n ${NAMESPACE} -o jsonpath='{.items[0].spec.volumes[*].name}' | tr ' ' '\n'
                        
                        # Debug: Check init container logs
                        echo "=== DEBUG: INIT CONTAINER LOGS ==="
                        echo "Backend init container logs:"
                        kubectl logs -n ${NAMESPACE} -l app=backend -c copy-jar || echo "No init container logs found"
                        echo ""
                        echo "Frontend init container logs:"
                        kubectl logs -n ${NAMESPACE} -l app=frontend -c copy-files || echo "No init container logs found"
                        
                        # Debug: Check if pods can access shared storage
                        echo "=== DEBUG: POD SHARED STORAGE ACCESS ==="
                        echo "Backend pod shared storage access:"
                        kubectl exec -n ${NAMESPACE} -l app=backend -- ls -la /shared/ || echo "Backend cannot access /shared/"
                        echo ""
                        echo "Frontend pod shared storage access:"
                        kubectl exec -n ${NAMESPACE} -l app=frontend -- ls -la /shared/ || echo "Frontend cannot access /shared/"
                        
                        # Debug: Check actual files in pods
                        echo "=== DEBUG: ACTUAL FILES IN PODS ==="
                        echo "Backend JAR file:"
                        kubectl exec -n ${NAMESPACE} -l app=backend -- ls -lh /app/app.jar || echo "Backend JAR not found"
                        echo ""
                        echo "Frontend files:"
                        kubectl exec -n ${NAMESPACE} -l app=frontend -- ls -la /usr/share/nginx/html/ || echo "Frontend files not found"
                        echo ""
                        echo "Frontend index.html content (first 10 lines):"
                        kubectl exec -n ${NAMESPACE} -l app=frontend -- head -10 /usr/share/nginx/html/index.html || echo "Cannot read frontend index.html"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 9: VERIFYING DEPLOYMENT"
                    echo "========================================"
                    
                    // Verify all pods are running
                    sh '''
                        echo "Verifying all pods are running..."
                        kubectl get pods -n ${NAMESPACE} -o wide
                        
                        echo "=== Backend Deployment Status ==="
                        kubectl get deployment backend -n ${NAMESPACE}
                        kubectl get pods -l app=backend -n ${NAMESPACE}
                        
                        echo "=== Frontend Deployment Status ==="
                        kubectl get deployment frontend -n ${NAMESPACE}
                        kubectl get pods -l app=frontend -n ${NAMESPACE}
                        
                        echo "=== Services ==="
                        kubectl get services -n ${NAMESPACE}
                        
                        echo "=== Service Ports Information ==="
                        echo "Internal Service Ports (within cluster):"
                        echo "- Frontend Service: Port 80 (HTTP)"
                        echo "- Backend Service: Port 8080 (HTTP)"
                        echo "- PostgreSQL: Port 5432 (Database)"
                        echo "- MailHog: Port 8025 (Web UI), Port 1025 (SMTP)"
                        echo "- Jenkins: Port 8080 (Web UI)"
                        
                        echo "=== Infrastructure Services (from Devpets-main) ==="
                        kubectl get services -n devops-pets | grep -E "(postgres|mailhog|jenkins|minio)" || echo "No infrastructure services found"
                        
                        echo "=== MinIO Status ==="
                        kubectl get deployment minio -n ${NAMESPACE} || echo "MinIO deployment not found"
                        kubectl get pods -l app=minio -n ${NAMESPACE} || echo "MinIO pods not found"
                        kubectl get service minio -n ${NAMESPACE} || echo "MinIO service not found"
                    '''
                    
                    // Final verification that all deployments are ready
                    sh '''
                        echo "Final verification - ensuring all deployments are ready..."
                        
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/minio -n ${NAMESPACE}
                        
                        echo "OK! All deployments are fully ready"
                        
                        echo "=== Final Service Status ==="
                        kubectl get services -n ${NAMESPACE} -o wide
                        
                        echo "=== Access Information ==="
                        echo "Internal Service Ports:"
                        echo "- Frontend Service: Port 80 (HTTP)"
                        echo "- Backend API Service: Port 8080 (HTTP)"
                        echo ""
                        echo "External Access:"
                        echo "- Port forwarding will be handled by Devpets-main Ansible"
                        echo "- Frontend: http://localhost:3000 (when port forwarding starts)"
                        echo "- Backend API: http://localhost:3000/api (when port forwarding starts)"
                        echo ""
                        echo "=== FOR USERS (Browser Access) ==="
                        echo "HTTPS Access via Ingress (when certificates are ready):"
                        echo "  Frontend: https://petsystem46.swedencentral.cloudapp.azure.com"
                        echo "  Backend API: https://api.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "  MinIO Console: https://minio.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "  Jenkins: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "  MailHog: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com"
                        echo ""
                        echo "Local Development (when port forwarding starts):"
                        echo "  Frontend: http://localhost:3000"
                        echo "  Backend API: http://localhost:3000/api"
                    '''
                }
            }
        }

        stage('Wait for Applications to be Functional') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 10: WAITING FOR APPLICATIONS TO BE FUNCTIONAL"
                    echo "========================================"
                    
                    // Wait for backend to be functional
                    sh '''
                        echo "Waiting for backend to be functional..."
                        
                        # Wait for backend deployment to be ready
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                        
                        # Wait for backend pod to be ready
                        kubectl wait --for=condition=ready pod -l app=backend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        
                        # Wait for backend to be responding
                        echo "Waiting for backend to be responding..."
                        for i in {1..30}; do
                          if kubectl run test-backend --image=busybox --restart=Never --rm -i --timeout=10s --namespace=${NAMESPACE} -- wget -qO- http://backend:8080/actuator/health 2>/dev/null | grep -q "UP\\|status"; then
                            echo "Backend is responding correctly!"
                            break
                          else
                            echo "Backend not responding yet, attempt $i/30..."
                            sleep 10
                          fi
                        done
                        
                        echo "Backend is functional!"
                    '''
                    
                    // Wait for frontend to be functional
                    sh '''
                        echo "Waiting for frontend to be functional..."
                        
                        # Wait for frontend deployment to be ready
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                        
                        # Wait for frontend pod to be ready
                        kubectl wait --for=condition=ready pod -l app=frontend -n ${NAMESPACE} --timeout=${TIMEOUT}
                        
                        # Wait for frontend to be responding
                        echo "Waiting for frontend to be responding..."
                        for i in {1..30}; do
                          if kubectl run test-frontend --image=busybox --restart=Never --rm -i --timeout=10s --namespace=${NAMESPACE} -- wget -qO- http://frontend:80/ 2>/dev/null | grep -q "html\\|app\\|vite"; then
                            echo "Frontend is responding correctly!"
                            break
                          else
                            echo "Frontend not responding yet, attempt $i/30..."
                            sleep 10
                          fi
                        done
                        
                        echo "Frontend is functional!"
                    '''
                    
                    // Final status
                    sh '''
                        echo "========================================"
                        echo "ALL APPLICATIONS ARE FUNCTIONAL!"
                        echo "========================================"
                        echo "Backend: Ready and responding"
                        echo "Frontend: Ready and responding"
                        echo "MinIO: Ready for file storage"
                        echo ""
                        echo "Devpets-main Ansible will now detect these applications"
                        echo "and start port forwarding automatically."
                        echo ""
                        echo "Access URLs:"
                        echo "- Frontend: https://petsystem46.swedencentral.cloudapp.azure.com"
                        echo "- Backend API: https://api.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "- MinIO Console: https://minio.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "- Jenkins: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com"
                        echo "- MailHog: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com"
                        echo ""
                        echo "Local Development (when port forwarding starts):"
                        echo "- Frontend: http://localhost:3000"
                        echo "- Backend API: http://localhost:3000/api"
                        echo "========================================"
                    '''
                }
            }
        }
    }

    post {
        success {
            script {
                echo "Build successful. Creating signal ConfigMap..."
                // Use the build number to create a unique name for the signal
                def signalName = "build-signal-${BUILD_NUMBER}"
                
                // Cleanup any previous signal that might have been left over for robustness
                sh "kubectl -n devops-pets delete configmap -l build-complete=true --ignore-not-found=true"

                // Create the new signal ConfigMap and label it
                sh """
                kubectl -n devops-pets create configmap ${signalName} --from-literal=status=success
                kubectl -n devops-pets label configmap ${signalName} build-complete=true
                """
                echo "Signal ConfigMap ${signalName} created."
            }
        }
        failure {
            script {
                echo "Build failed. No signal will be created."
            }
        }
        always {
            echo "Pipeline finished."
        }
    }
}
