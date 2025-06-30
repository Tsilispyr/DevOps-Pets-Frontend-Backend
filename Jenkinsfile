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

        stage('Setup LoadBalancer') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 2: SETTING UP LOADBALANCER"
                    echo "========================================"
                    
                    // Install MetalLB LoadBalancer if not already installed
                    sh '''
                        echo "Checking if MetalLB LoadBalancer is installed..."
                        
                        if ! kubectl get namespace metallb-system 2>/dev/null; then
                            echo "Installing MetalLB LoadBalancer..."
                            kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
                            
                            echo "Waiting for MetalLB to be ready..."
                            kubectl wait --for=condition=ready pod -l app=metallb -n metallb-system --timeout=120s
                            
                            echo "Configuring MetalLB IP address pool..."
                            cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.0.200-172.18.0.250
EOF
                            
                            cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
                            
                            echo "MetalLB LoadBalancer installed and configured"
                        else
                            echo "MetalLB LoadBalancer already installed"
                        fi
                        
                        echo "Verifying MetalLB status..."
                        kubectl get pods -n metallb-system
                    '''
                }
            }
        }

        stage('Complete Cleanup') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 3: COMPLETE CLEANUP"
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
              value: mailhog
            - name: SPRING_MAIL_PORT
              value: "1025"
            - name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI
              value: http://localhost:8083/realms/petsystem
            - name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_AUDIENCES
              value: backend
          command: ["java", "-jar", "/app/app.jar"]
          volumeMounts:
            - name: app-jar
              mountPath: /app
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
                        kubectl wait --for=condition=ready pod/file-copy-pod -n ${NAMESPACE} --timeout=60s
                        
                        # Copy JAR to shared storage
                        echo "Copying JAR to shared storage..."
                        kubectl cp Ask/target/app.jar ${NAMESPACE}/file-copy-pod:/shared/app.jar
                        echo "OK! JAR copied to shared storage"
                        
                        # Copy frontend files to shared storage
                        echo "Copying frontend files to shared storage..."
                        kubectl cp frontend/dist/ ${NAMESPACE}/file-copy-pod:/shared/frontend/
                        echo "OK! Frontend files copied to shared storage"
                        
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
                        echo ""
                        echo "External Access Ports:"
                        echo "- Ingress Controller: Port 80 (HTTP), Port 443 (HTTPS)"
                        echo "- LoadBalancer Services: External IPs assigned by MetalLB"
                        echo "- Kind Cluster: Uses host port mappings from kind-config.yaml"
                        
                        echo "=== Infrastructure Services (from Devpets-main) ==="
                        kubectl get services -n devops-pets | grep -E "(postgres|mailhog|jenkins)" || echo "No infrastructure services found"
                        
                        echo "=== LoadBalancer Services ==="
                        echo "Waiting for LoadBalancer services to get external IPs..."
                        kubectl get services -n ${NAMESPACE} -o wide
                    '''
                    
                    // Final verification that all deployments are ready
                    sh '''
                        echo "Final verification - ensuring all deployments are ready..."
                        
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                        
                        echo "OK! All deployments are fully ready"
                        
                        echo "=== Final Service Status ==="
                        kubectl get services -n ${NAMESPACE} -o wide
                        
                        echo "=== Access Information ==="
                        echo "Internal Service Ports:"
                        echo "- Frontend Service: Port 80 (HTTP)"
                        echo "- Backend API Service: Port 8080 (HTTP)"
                        echo ""
                        echo "External Access:"
                        echo "- Ingress: http://localhost (routes to internal services)"
                        echo "- LoadBalancer: Check external IPs above for direct access"
                        echo "- Kind Cluster: Uses host port mappings for external access"
                        echo ""
                        echo "=== FOR USERS (Browser Access) ==="
                        echo "If Ingress is working:"
                        echo "  Frontend: http://localhost"
                        echo "  Backend API: http://localhost/api"
                        echo ""
                        echo "If Ingress failed (LoadBalancer):"
                        echo "  Check LoadBalancer IPs above and use:"
                        echo "  Frontend: http://<frontend-loadbalancer-ip>"
                        echo "  Backend API: http://<backend-loadbalancer-ip>:8080"
                    '''
                }
            }
        }

        stage('Setup Ingress') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 10: SETTING UP INGRESS"
                    echo "========================================"
                    
                    // Install nginx-ingress controller if not already installed
                    sh '''
                        echo "Checking if nginx-ingress controller is installed..."
                        
                        if ! kubectl get namespace ingress-nginx 2>/dev/null; then
                            echo "Installing nginx-ingress controller..."
                            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml
                            
                            echo "Waiting for nginx-ingress controller to be ready..."
                            echo "Note: This may take a few minutes on Kind cluster..."
                            
                            # Wait with longer timeout and better error handling
                            if kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=600s; then
                                echo "✅ nginx-ingress controller installed successfully"
                            else
                                echo "⚠️  nginx-ingress controller installation timed out"
                                echo "This is common in Kind clusters. Checking status..."
                                kubectl get pods -n ingress-nginx
                                kubectl describe pods -n ingress-nginx -l app.kubernetes.io/component=controller
                                
                                echo "Continuing with LoadBalancer services instead..."
                                echo "The application will be accessible via LoadBalancer IPs"
                            fi
                        else
                            echo "✅ nginx-ingress controller already installed"
                        fi
                        
                        # Only create Ingress if nginx-ingress is working
                        if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase=Running 2>/dev/null | grep -q ingress-nginx-controller; then
                            echo "Creating Ingress resource..."
                            cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: ${NAMESPACE}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 8080
EOF
                            
                            echo "Waiting for Ingress to be ready..."
                            kubectl wait --for=condition=ready ingress/app-ingress -n ${NAMESPACE} --timeout=60s
                            
                            echo "✅ Ingress configured successfully"
                            echo "Access your application at:"
                            echo "- Frontend: http://localhost"
                            echo "- Backend API: http://localhost/api"
                        else
                            echo "⚠️  nginx-ingress controller not ready, using LoadBalancer services"
                            echo "Application will be accessible via LoadBalancer IPs"
                            echo "Check 'kubectl get services -n devops-pets' for external IPs"
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed!'
        }
        success {
            echo '''
            ========================================
            DEPLOYMENT SUCCESSFUL!
            ========================================
            Applications have been built and deployed:
            - Backend: Spring Boot JAR deployed (Port: 8080)
            - Frontend: Vue.js build deployed with nginx proxy (Port: 80)
            - LoadBalancer: MetalLB configured with external IPs
            - Ingress: nginx-ingress controller configured (if available)
            
            Access Points:
            ========================================
            PRIMARY ACCESS (INGRESS):
            - Frontend: http://localhost (Port: 80)
            - Backend API: http://localhost/api (Port: 8080)
            
            ALTERNATIVE ACCESS (LOADBALANCER):
            - Check LoadBalancer IPs: kubectl get services -n devops-pets
            - Frontend: http://<frontend-loadbalancer-ip> (Port: 80)
            - Backend API: http://<backend-loadbalancer-ip>:8080 (Port: 8080)
            
            ========================================
            FOR USERS (Browser Access)
            ========================================
            If Ingress is working:
            - Frontend: http://localhost
            - Backend API: http://localhost/api
            
            If Ingress failed (LoadBalancer):
            - Check LoadBalancer IPs with: kubectl get services -n devops-pets
            - Frontend: http://<frontend-loadbalancer-ip>
            - Backend API: http://<backend-loadbalancer-ip>:8080
            
            Note: The LoadBalancer IPs will be shown in the service list above
            
            ========================================
            USEFUL COMMANDS
            ========================================
            - Check services: kubectl get services -n devops-pets
            - Check ingress: kubectl get ingress -n devops-pets
            - Check ingress controller: kubectl get pods -n ingress-nginx
            - View logs: kubectl logs -n devops-pets <pod-name>
            - Check nginx config: kubectl exec -n devops-pets <frontend-pod> -- cat /etc/nginx/conf.d/default.conf
            - Check service ports: kubectl get services -n devops-pets -o wide
            ========================================
            '''
        }
        failure {
            echo 'Deployment failed! Check the logs for more details.'
        }
    }
}
