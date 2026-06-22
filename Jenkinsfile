pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building images...'
                sh 'docker compose -f ${COMPOSE_FILE} build'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying containers...'
                sh 'docker compose -f ${COMPOSE_FILE} up -d'
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying services...'
                sh 'docker compose -f ${COMPOSE_FILE} ps'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed - rolling back...'
            sh 'docker compose -f ${COMPOSE_FILE} down'
        }
    }
}
