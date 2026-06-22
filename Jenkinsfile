pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Cloning repository...'
                checkout scm
                sh 'git log -1 --pretty=format:"Commit: %h | Author: %an | Message: %s"'
            }
        }

        stage('Build') {
            steps {
                echo '🔨 Building images...'
                sh 'docker compose -f ${COMPOSE_FILE} build --no-cache 2>&1 | tee build.log'
                echo '✅ Build complete'
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying containers...'
                sh 'docker compose -f ${COMPOSE_FILE} up -d 2>&1 | tee deploy.log'
                echo '✅ Deploy complete'
            }
        }

        stage('Verify') {
            steps {
                echo '🔍 Verifying services...'
                sh 'docker compose -f ${COMPOSE_FILE} ps'
                sh 'docker compose -f ${COMPOSE_FILE} logs --tail=20'
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed successfully - app is live'
        }
        failure {
            echo '❌ Pipeline failed - rolling back...'
            sh 'docker compose -f ${COMPOSE_FILE} down'
        }
    }
}
