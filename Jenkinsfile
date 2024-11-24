pipeline {
    agent any

    environment {
		SONAR_PROJECT_KEY = 'complete-cicd'
		SONAR_SCANNER_HOME = tool 'SonarQubeScanner'
	}

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

		stage('SonarQube Analysis'){
			steps {
				withCredentials([string(credentialsId: 'complete-cicd-token', variable: 'SONAR_TOKEN')]) {

					withSonarQubeEnv('SonarQube') {
    					sh """
						${SONAR_SCANNER_HOME}/bin/sonar-scanner \
						-Dsonar.projectKey=${SONAR_PROJECT_KEY} \
						-Dsonar.sources=. \
						-Dsonar.host.url=http://sonarqube:9000 \
						-Dsonar.login=${SONAR_TOKEN}
						"""
					}
				}
			}
		}

		stage('Push Image to ECR'){
			steps {
				sh """
				aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 358966077876.dkr.ecr.eu-central-1.amazonaws.com
				docker tag fastapi-image 358966077876.dkr.ecr.eu-central-1.amazonaws.com/test_web_app:latest
				docker push 358966077876.dkr.ecr.eu-central-1.amazonaws.com/test_web_app:latest
				"""
			}
		}

		stage('Deploy') {
            steps {
                sh "helm upgrade --install release-1 ./fastapi-chart --namespace fastapi"
            }
        }
    }
}
