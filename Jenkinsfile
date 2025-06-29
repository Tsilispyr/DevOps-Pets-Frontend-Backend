pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Build Docker Images') {
            steps {
                dir('Ask') {
                    sh 'docker build -t devops-pets-backend:latest .'
                }
                dir('frontend') {
                    sh 'docker build -t devops-pets-frontend:latest .'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'  // Only deploy from main branch
            }
            steps {
                withCredentials([string(credentialsId: 'jenkins-kubeconfig-text', variable: 'KUBECONFIG_CONTENT')]) {
                    writeFile file: 'jenkins-kubeconfig', text: env.KUBECONFIG_CONTENT
                    sh 'export KUBECONFIG=$PWD/jenkins-kubeconfig && kubectl apply -R -f k8s/'
                    sh 'export KUBECONFIG=$PWD/jenkins-kubeconfig && kubectl rollout restart deployment backend'
                    sh 'export KUBECONFIG=$PWD/jenkins-kubeconfig && kubectl rollout restart deployment frontend'
                    echo 'Waiting for deployments to complete...'
                    sh 'export KUBECONFIG=$PWD/jenkins-kubeconfig && kubectl wait --for=condition=available --timeout=120s deployment/backend'
                    sh 'export KUBECONFIG=$PWD/jenkins-kubeconfig && kubectl wait --for=condition=available --timeout=120s deployment/frontend'
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
            The backend and frontend have been deployed.
            Backend should be available at: http://localhost:30080
            Frontend should be available at: http://localhost:30000
            MailHog UI: http://localhost:8025
            PostgreSQL: localhost:5432
            '''
        }
        failure {
            echo 'Deployment failed! Check the logs for more details.'
        }
    }
}
