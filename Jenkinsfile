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
                echo 'Project files verified'
            }
        }

        stage('Build Backend') {
            steps {
                sh 'docker build -t self-healing-backend:v1 ./backend'
            }
        }

        stage('Build Frontend') {
            steps {
                sh 'docker build -t self-healing-frontend:v2 ./frontend'
            }
        }
    }
}