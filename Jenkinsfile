pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/task-6']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/volha10/fastapi-k8s.git']])
            }
        }

        stage('Build') {
            steps {
                sh "docker build . -t fastapi-image"
            }
        }
    }
}
