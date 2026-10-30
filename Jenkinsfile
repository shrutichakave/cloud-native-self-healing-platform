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
                sh 'docker build -t self-healing-backend:v2 ./backend'
            }
        }

        stage('Scan Backend Image') {
            steps {
                sh '/usr/bin/trivy --config "" image --severity HIGH,CRITICAL self-healing-backend:v2'
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
                    docker tag self-healing-backend:v2 \
                        "$ECR_REGISTRY/self-healing-backend:v2"
                    docker push "$ECR_REGISTRY/self-healing-backend:v2"
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
                    set -e

                    # Install kubectl for the Jenkins user
                    ARCH=$(uname -m)
                    if [ "$ARCH" = "x86_64" ]; then ARCH=amd64; fi
                    if [ "$ARCH" = "aarch64" ]; then ARCH=arm64; fi

                    VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
                    curl -L -o kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl"
                    mkdir -p "$HOME/bin"
                    install -m 0755 kubectl "$HOME/bin/kubectl"
                    export PATH="$HOME/bin:$PATH"

                    kubectl version --client

                    # Connect to EKS and deploy
                    aws eks update-kubeconfig --name self-healing-eks --region ap-south-1
                    kubectl set image deployment/backend backend=$ECR_REGISTRY/self-healing-backend:v2
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
