# Jenkins Pipeline Setup and Deployment Documentation

This guide provides steps to create Jenkins pipeline for automating the build, testing, and deployment of the FastAPI application. It uses Jenkins for CI/CD, Docker for containerization, and Kubernetes for deployment.

## Prerequisites

Ensure that the following tools are installed:

1. [Jenkins](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/)
2. [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
3. Docker
4. [SonarQube](https://hub.docker.com/_/sonarqube) with plugins SonarQubeScanner, Sonar Quality Gates
5. [K3s](https://k3s.io/)
6. [Helm](https://helm.sh/docs/intro/install/)

## Pipeline Configuration

### 1. Set Up Jenkins
- Log in to Jenkins.
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
- Create a new pipeline job.
- Point the job to the Jenkinsfile in the repository.

### 2. Environment Variables and Secrets:
The following environment variables and secrets must be added in the global configuration:
- Git token
- AWS_ACCOUNT_ID: AWS account ID.
- AWS_REGION: Deployment region.
- AWS_ECR_REPO_NAME: AWS ECR repository name.
- KUBECONFIG: Kubernetes config secret file (e.g. ~/.kube/config).
- SONAR_TOKEN 

### 3. AWS IAM permissions
[Accessing One Amazon ECR Repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security_iam_id-based-policy-examples.html#security_iam_id-based-policy-examples-access-one-bucket)

## Deployment Process
Step-by-step instructions on how the deployment works.

- Checkout the Repository:
    ```
    git clone https://github.com/volha10/fastapi-k8s.git
    cd fastapi-chart
    ```

- Build Stage:
    ```
    docker build . -t fastapi-image
    ```
    Builds the Docker image.
- Test Stage:
    ```
    docker run fastapi-image pytest
    ```
    Executes tests using pytest.

- Push Image to ECR:
    ```
    AWS_REGION=us-east-1
    AWS_ACCOUNT_ID=123456789012  
    AWS_ECR_REPO_NAME=sample_repo 
  
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    docker tag $DOCKER_IMAGE $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:latest
    ```
    Logs into the AWS registry and pushes the built image.

- Deploy to Kubernetes:
    ```
    helm upgrade --install release-1 ./fastapi-chart \
      --set image.repository="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME" \
      --namespace fastapi
    ```
  
    Updates the deployment in the Kubernetes cluster using Helm.
    > **Note**: `fastapi` namespace must be created.

    Confirm the application is deployed:
    ```
    kubectl get all -n fastapi
    ```

## Troubleshooting
* `Docker Permission Denied.` 
  Ensure the Jenkins user is added to the Docker group:
  ```
  sudo usermod -a -G docker jenkins
  ```

* `SonarQube Timeout.` 
  Check if SonarQube is reachable from Jenkins (if Jenkins and SonarQube are on the same machine - use localhost for sonarqube host url):
  ```commandline
  curl http://sonarqube-server:9000
  ```

* `Error reading /home/ec2-user/.docker/config.json: no such file or directory.`
  This file is typically created when you log in to a Docker registry, such as AWS ECR, using the docker login command.
  ```
  aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
  ```

* `Kubernetes cluster unreachable.`
  Make sure Jenkins creds from ~/.kube/config is created.

* `Unable to retrieve some image pull secrets (awsecr-cred).` or `pull access denied, repository does not exist or may require authorization: authorization failed: no basic auth credentials`
  ```commandline
  kubectl create secret generic awsecr-cred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson \
    --namespace fastapi
  ```



