
pipeline {
    agent any

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
                sh 'trivy image --severity HIGH,CRITICAL self-healing-backend:v1'
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
    }

    post {
        success {
            echo 'Build and security scans completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the Console Output for details.'
        }
    }
}
