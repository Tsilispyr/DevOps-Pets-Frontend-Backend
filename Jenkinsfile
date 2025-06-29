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
        TIMEOUT = "300s"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Complete Cleanup') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "========================================"
                    echo "STEP 1: COMPLETE CLEANUP"
                    echo "========================================"
                    
                    withCredentials([string(credentialsId: 'jenkins-kubeconfig-text', variable: 'KUBECONFIG_CONTENT')]) {
                        writeFile file: 'jenkins-kubeconfig', text: env.KUBECONFIG_CONTENT
                        
                        // Stop all port forwarding
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
                            pkill -f "kubectl port-forward" || true
                            sleep 3
                        '''
                        
                        // Delete existing deployments and services
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
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
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "========================================"
                    echo "STEP 2: BUILDING AND PUSHING DOCKER IMAGES"
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

        stage('Update Kubernetes Manifests') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "========================================"
                    echo "STEP 3: UPDATING KUBERNETES MANIFESTS"
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
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "========================================"
                    echo "STEP 4: DEPLOYING TO KUBERNETES"
                    echo "========================================"
                    
                    withCredentials([string(credentialsId: 'jenkins-kubeconfig-text', variable: 'KUBECONFIG_CONTENT')]) {
                        writeFile file: 'jenkins-kubeconfig', text: env.KUBECONFIG_CONTENT
                        
                        // Apply all Kubernetes resources
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
                            echo "Applying Kubernetes resources..."
                            kubectl apply -R -f k8s/ -n ${NAMESPACE}
                            echo "OK! Resources applied"
                        '''
                        
                        // Wait for deployments to be ready
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
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
        }

        stage('Verify Deployment') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "========================================"
                    echo "STEP 5: VERIFYING DEPLOYMENT"
                    echo "========================================"
                    
                    withCredentials([string(credentialsId: 'jenkins-kubeconfig-text', variable: 'KUBECONFIG_CONTENT')]) {
                        writeFile file: 'jenkins-kubeconfig', text: env.KUBECONFIG_CONTENT
                        
                        // Verify all pods are running
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
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
                        '''
                        
                        // Final verification that all deployments are ready
                        sh '''
                            export KUBECONFIG=$PWD/jenkins-kubeconfig
                            echo "Final verification - ensuring all deployments are ready..."
                            
                            kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/backend -n ${NAMESPACE}
                            kubectl wait --for=condition=available --timeout=${TIMEOUT} deployment/frontend -n ${NAMESPACE}
                            
                            echo "OK! All deployments are fully ready"
                        '''
                    }
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
