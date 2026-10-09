pipeline {
    agent any

    stages {
        stage('Checkout Verification') {
            steps {
                echo 'Jenkins pipeline is running!'
                sh 'git rev-parse --short HEAD'
            }
        }

        stage('Verify Project Files') {
            steps {
                sh 'test -f backend/server.js'
                sh 'test -f frontend/index.html'
                sh 'test -f backend/Dockerfile'
                sh 'test -f frontend/Dockerfile'

                echo 'Project files verified successfully!'
            }
        }
    }
}
