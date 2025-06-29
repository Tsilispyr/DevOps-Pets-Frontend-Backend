pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
    }

    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        BACKEND_IMAGE = 'devops-pets-backend'
        FRONTEND_IMAGE = 'devops-pets-frontend'
        IMAGE_TAG = "${BUILD_NUMBER}"
        NAMESPACE = "devops-pets"
        CLUSTER_NAME = "devops-pets"
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
                    
                    // Get current cluster name and export kubeconfig
                    sh '''
                        echo "Getting current kind cluster..."
                        CURRENT_CLUSTER=$(kind get clusters | head -n 1)
                        echo "Current cluster: $CURRENT_CLUSTER"
                        
                        if [ -z "$CURRENT_CLUSTER" ]; then
                            echo "ERR! No kind cluster found. Please ensure Devpets-main is deployed first."
                            exit 1
                        fi
                        
                        echo "Exporting kubeconfig for cluster: $CURRENT_CLUSTER"
                        kind export kubeconfig --name $CURRENT_CLUSTER
                        echo "OK! Kubeconfig exported"
                        
                        # Verify cluster connection
                        kubectl cluster-info
                        kubectl get nodes
                        
                        # Check if devops-pets namespace exists
                        if kubectl get namespace devops-pets 2>/dev/null; then
                            echo "OK! devops-pets namespace exists"
                        else
                            echo "Creating devops-pets namespace..."
                            kubectl create namespace devops-pets
                        fi
                    '''
                }
            }
        }

        stage('Setup Docker Registry') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 2: SETTING UP DOCKER REGISTRY"
                    echo "========================================"
                    
                    // Start local Docker registry if not running
                    sh '''
                        if ! docker ps | grep -q docker-registry; then
                            echo "Starting local Docker registry..."
                            docker run -d \
                              --name docker-registry \
                              --restart=always \
                              -p 5000:5000 \
                              -v registry-data:/var/lib/registry \
                              registry:2
                            echo "OK! Docker registry started"
                        else
                            echo "OK! Docker registry already running"
                        fi
                        
                        # Wait for registry to be ready
                        sleep 5
                        curl -s http://localhost:5000/v2/_catalog || echo "Registry not ready yet, will be available soon"
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
                    
                    // Clean up old Docker images
                    sh '''
                        echo "Cleaning old Docker images..."
                        docker images | grep devops-pets | tail -n +6 | awk '{print $3}' | xargs -r docker rmi -f || true
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

        stage('Build and Push Docker Images') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 4: BUILDING AND PUSHING DOCKER IMAGES"
                    echo "========================================"
                    
                    // Build backend image
                    dir('Ask') {
                        sh """
                            echo "Building backend image: ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}"
                            docker build -t ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG} .
                            docker tag ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                            echo "OK! Backend image built"
                        """
                    }
                    
                    // Build frontend image
                    dir('frontend') {
                        sh """
                            echo "Building frontend image: ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}"
                            docker build -t ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG} .
                            docker tag ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                            echo "OK! Frontend image built"
                        """
                    }
                    
                    // Push images to registry
                    sh """
                        echo "Pushing images to registry..."
                        docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                        docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                        echo "OK! Images pushed successfully"
                    """
                }
            }
        }

        stage('Load Images to Cluster') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 5: LOADING IMAGES TO CLUSTER"
                    echo "========================================"
                    
                    // Get current cluster name and load images
                    sh '''
                        CURRENT_CLUSTER=$(kind get clusters | head -n 1)
                        echo "Loading images into kind cluster: $CURRENT_CLUSTER"
                        kind load docker-image ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG} --name $CURRENT_CLUSTER
                        kind load docker-image ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG} --name $CURRENT_CLUSTER
                        echo "OK! Images loaded successfully"
                    '''
                }
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 6: UPDATING KUBERNETES MANIFESTS"
                    echo "========================================"
                    
                    // Update backend deployment with new image
                    sh """
                        echo "Updating backend deployment with image: ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}"
                        sed -i 's|image: .*|image: ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${IMAGE_TAG}|g' k8s/backend/backend-deployment.yaml
                    """
                    
                    // Update frontend deployment with new image
                    sh """
                        echo "Updating frontend deployment with image: ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}"
                        sed -i 's|image: .*|image: ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${IMAGE_TAG}|g' k8s/frontend/frontend-deployment.yaml
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "========================================"
                    echo "STEP 7: DEPLOYING TO KUBERNETES"
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
                    echo "STEP 8: SETTING UP PORT FORWARDING"
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
                        
                        echo "=== Infrastructure Services (from Devpets-main) ==="
                        kubectl get services -n devops-pets | grep -E "(postgres|mailhog|jenkins)"
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
            Fresh images have been built and deployed:
            - Backend: localhost:5000/devops-pets-backend:BUILD_NUMBER
            - Frontend: localhost:5000/devops-pets-frontend:BUILD_NUMBER
            
            Access Points:
            - Backend API: http://localhost:30080
            - Frontend App: http://localhost:30000
            - MailHog UI: http://localhost:8025
            - PostgreSQL: localhost:5432
            - Docker Registry: http://localhost:5000
            
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
        cleanup {
            // Clean up old images (keep last 5 builds)
            sh '''
                echo "Cleaning up old Docker images..."
                docker images | grep devops-pets | tail -n +6 | awk '{print $3}' | xargs -r docker rmi -f || true
            '''
        }
    }
}
