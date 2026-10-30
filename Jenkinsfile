pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '290993050816.dkr.ecr.ap-south-1.amazonaws.com'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Starting CI/CD Pipeline'
                sh 'git rev-parse --short HEAD'
            }
        }

        stage('Verify Files') {
            steps {
                sh 'test -f backend/server.js'
                sh 'test -f frontend/index.html'
                echo 'Project files verified successfully'
            }
        }

        stage('Build Backend') {
            steps {
                sh 'docker build -t self-healing-backend:v1 ./backend'
            }
        }

        stage('Scan Backend Image') {
            steps {
                sh '/usr/bin/trivy --config "" image --severity HIGH,CRITICAL self-healing-backend:v1'
            }
        }

        stage('Build Frontend') {
            steps {
                sh 'docker build -t self-healing-frontend:v2 ./frontend'
            }
        }

        stage('Scan Frontend Image') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL self-healing-frontend:v2'
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                 sh '''
            set -e
            /usr/local/bin/aws ecr get-login-password --region ap-south-1 \
              | docker login --username AWS --password-stdin 290993050816.dkr.ecr.ap-south-1.amazonaws.com
        '''
            }
        }

        stage('Push Backend to ECR') {
            steps {
                sh '''
                    docker tag self-healing-backend:v1 \
                        "$ECR_REGISTRY/self-healing-backend:v1"
                    docker push "$ECR_REGISTRY/self-healing-backend:v1"
                '''
            }
        }

        stage('Push Frontend to ECR') {
            steps {
                sh '''
                    docker tag self-healing-frontend:v2 \
                        "$ECR_REGISTRY/self-healing-frontend:v2"
                    docker push "$ECR_REGISTRY/self-healing-frontend:v2"
                '''
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig --name self-healing-eks --region ap-south-1
                    kubectl set image deployment/backend backend=$ECR_REGISTRY/self-healing-backend:v1
                    kubectl set image deployment/frontend frontend=$ECR_REGISTRY/self-healing-frontend:v2
                    kubectl rollout status deployment/backend
                    kubectl rollout status deployment/frontend
                '''
            }
        }

    }

    post {
        success {
            echo 'Build, security scans, and ECR image pushes completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the Console Output for details.'
        }
        always {
            sh 'docker logout "$ECR_REGISTRY" || true'
        }
    }
}
