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
                    echo "STEP 3: PREPARING FILES FOR DEPLOYMENT"
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

        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 4: UPDATING KUBERNETES MANIFESTS"
                    echo "========================================"
                    
                    // Update backend deployment to use emptyDir and copy JAR
                    sh '''
                        echo "Updating backend deployment for emptyDir..."
                        cat > k8s/backend/backend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
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
          command: ['sh', '-c', 'cp /source/app.jar /app/app.jar']
          volumeMounts:
            - name: source-jar
              mountPath: /source
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
              value: jdbc:postgresql://postgres.default.svc.cluster.local:5432/petdb
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
        - name: source-jar
          configMap:
            name: backend-jar
        - name: app-jar
          emptyDir: {}
EOF
                    '''
                    
                    // Update frontend deployment to use emptyDir and copy dist files
                    sh '''
                        echo "Updating frontend deployment for emptyDir..."
                        cat > k8s/frontend/frontend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
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
          command: ['sh', '-c', 'cp -r /source/* /app/']
          volumeMounts:
            - name: source-files
              mountPath: /source
            - name: frontend-files
              mountPath: /app
      containers:
        - name: frontend
          image: nginx:stable-alpine
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          volumeMounts:
            - name: frontend-files
              mountPath: /usr/share/nginx/html
      volumes:
        - name: source-files
          configMap:
            name: frontend-files
        - name: frontend-files
          emptyDir: {}
EOF
                    '''
                }
            }
        }

        stage('Create ConfigMaps') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 5: CREATING CONFIGMAPS"
                    echo "========================================"
                    
                    // Create ConfigMap for backend JAR
                    sh '''
                        echo "Creating ConfigMap for backend JAR..."
                        kubectl create configmap backend-jar --from-file=app.jar=Ask/target/app.jar -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        echo "OK! Backend JAR ConfigMap created"
                    '''
                    
                    // Create ConfigMap for frontend files
                    sh '''
                        echo "Creating ConfigMap for frontend files..."
                        kubectl create configmap frontend-files --from-file=frontend/dist/ -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        echo "OK! Frontend files ConfigMap created"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 6: DEPLOYING TO KUBERNETES"
                    echo "========================================"
                    
                    // Apply all Kubernetes resources
                    sh '''
                        echo "Applying Kubernetes resources..."
                        kubectl apply -R -f k8s/ -n ${NAMESPACE}
                        echo "OK! Resources applied"
                    '''
                    
                    // Wait for deployments to be ready
                    sh '''
                        echo "Waiting for deployments to be ready..."
                        
                        echo "Waiting for backend deployment..."
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                        echo "OK! Backend deployment is ready"
                        
                        echo "Waiting for frontend deployment..."
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                        echo "OK! Frontend deployment is ready"
                    '''
                }
            }
        }

        stage('Setup Port Forwarding') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 7: SETTING UP PORT FORWARDING"
                    echo "========================================"
                    
                    // Kill any existing port forwards
                    sh '''
                        pkill -f "kubectl port-forward.*backend" || true
                        pkill -f "kubectl port-forward.*frontend" || true
                        sleep 2
                    '''
                    
                    // Start backend port forward
                    sh '''
                        echo "Starting backend port forward (30080:8080)..."
                        kubectl port-forward -n ${NAMESPACE} service/backend 30080:8080 &
                        BACKEND_PID=$!
                        echo $BACKEND_PID > /tmp/backend-port-forward.pid
                        echo "OK! Backend port forward is running (PID: $BACKEND_PID)"
                    '''
                    
                    // Start frontend port forward
                    sh '''
                        echo "Starting frontend port forward (30000:80)..."
                        kubectl port-forward -n ${NAMESPACE} service/frontend 30000:80 &
                        FRONTEND_PID=$!
                        echo $FRONTEND_PID > /tmp/frontend-port-forward.pid
                        echo "OK! Frontend port forward is running (PID: $FRONTEND_PID)"
                    '''
                    
                    // Wait for port forwards to establish
                    sh '''
                        echo "Waiting for port forwards to establish..."
                        sleep 5
                        
                        # Check if port forwards are running
                        if [ -f /tmp/backend-port-forward.pid ]; then
                            BACKEND_PID=$(cat /tmp/backend-port-forward.pid)
                            if kill -0 $BACKEND_PID 2>/dev/null; then
                                echo "OK! Backend port forward is running"
                            else
                                echo "ERR! Backend port forward failed to start"
                            fi
                        fi
                        
                        if [ -f /tmp/frontend-port-forward.pid ]; then
                            FRONTEND_PID=$(cat /tmp/frontend-port-forward.pid)
                            if kill -0 $FRONTEND_PID 2>/dev/null; then
                                echo "OK! Frontend port forward is running"
                            else
                                echo "ERR! Frontend port forward failed to start"
                            fi
                        fi
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 8: VERIFYING DEPLOYMENT"
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
                        
                        echo "=== Infrastructure Services (from Devpets-main) ==="
                        kubectl get services -n devops-pets | grep -E "(postgres|mailhog|jenkins)" || echo "No infrastructure services found"
                    '''
                    
                    // Final verification that all deployments are ready
                    sh '''
                        echo "Final verification - ensuring all deployments are ready..."
                        
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                        kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                        
                        echo "OK! All deployments are fully ready"
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
            - Backend: Spring Boot JAR deployed
            - Frontend: Vue.js build deployed
            
            Access Points:
            - Backend API: http://localhost:30080
            - Frontend App: http://localhost:30000
            - MailHog UI: http://localhost:8025
            - PostgreSQL: localhost:5432
            
            ========================================
            PORT FORWARDING STATUS
            ========================================
            Backend port forward: Running on localhost:30080
            Frontend port forward: Running on localhost:30000
            PID files: /tmp/backend-port-forward.pid, /tmp/frontend-port-forward.pid
            
            ========================================
            USEFUL COMMANDS
            ========================================
            - Check status: kubectl get all -n devops-pets
            - View logs: kubectl logs -n devops-pets <pod-name>
            - Stop forwarding: pkill -f 'kubectl port-forward'
            ========================================
            '''
        }
        failure {
            echo 'Deployment failed! Check the logs for more details.'
        }
    }
}
