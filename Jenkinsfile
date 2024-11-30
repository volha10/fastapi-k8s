pipeline {
    agent any

    environment {
		SONAR_PROJECT_KEY = 'FastaApi-CICD'
		SONAR_SCANNER_HOME = tool 'SonarQubeScanner'

		DOCKER_IMAGE = 'fastapi-image'

		MANUAL_STEP_APPROVED = false
	}

    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/task-6']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/volha10/fastapi-k8s.git']])
            }
        }

        stage('Build') {
            steps {
                sh 'docker build . -t $DOCKER_IMAGE'
            }
        }

        stage('Test') {
            steps {
                sh 'docker run $DOCKER_IMAGE pytest'
            }
        }

		stage('SonarQube Analysis'){
			steps {
				withSonarQubeEnv('SonarQube') {
    				sh """
					${SONAR_SCANNER_HOME}/bin/sonar-scanner \
						-Dsonar.projectKey=${SONAR_PROJECT_KEY} \
						-Dsonar.sources=. \
					"""
				}
			}
		}

		stage('Push Image to ECR'){
		    steps {
		        script {
		            MANUAL_STEP_APPROVED = input(
                        message: 'Do you want to proceed with pushing to AWS ECR',
                        parameters: [booleanParam(defaultValue: false, description: '', name: 'Push to AWS ECR')]
                    )

                    withCredentials([
                        string(credentialsId: 'AWS_ACCOUNT_ID', variable: 'AWS_ACCOUNT_ID'),
                        string(credentialsId: 'AWS_REGION', variable: 'AWS_REGION'),
                        string(credentialsId: 'AWS_ECR_REPO_NAME', variable: 'AWS_ECR_REPO_NAME')
                    ]) {
                        sh '''
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                        docker tag $DOCKER_IMAGE $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:latest
                        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:latest
                        echo $MANUAL_STEP_APPROVED
                        '''
                    }
                }
            }
		}

		stage('Deploy') {
		    when {
                expression { return MANUAL_STEP_APPROVED } // Run only if approved
            }
            steps {
                withCredentials([file(credentialsId: 'KUBECONFIG_CRED', variable: 'KUBECONFIG')]) {
                    sh '''helm upgrade --install release-1 ./fastapi-chart --namespace fastapi'''
                }
            }
        }
    }
}
