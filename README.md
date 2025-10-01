## 🚀 Jenkins + Docker + Kubernetes on EC2 Setup Guide

This guide explains how to set up Jenkins, Docker, and Kubernetes (MicroK8s) on an AWS EC2 instance to build and deploy applications.

1️⃣ Launch EC2 Instance

Instance type: t2.medium

Storage: 50GB volume

Security Group: Allow all ports and all protocols (for testing/demo purposes – not recommended for production).

2️⃣ Connect to Server & Install Docker + Kubernetes

* Become root
sudo -i

* Update system
apt update && apt install docker.io -y

* Install snap and MicroK8s (Kubernetes)

apt install snap -y && snap install microk8s --classic

Configure kubectl alias
alias kubectl='microk8s kubectl'
source <(microk8s kubectl completion bash)
complete -F __start_kubectl kubectl
source ~/.bashrc

3️⃣ Install JDK 21 for Jenkins
sudo apt update
sudo apt install fontconfig openjdk-21-jre -y
java -version

4️⃣ Install Jenkins

* Add Jenkins key & repo
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

* Install Jenkins
sudo apt update
sudo apt install jenkins -y

5️⃣ Configure Jenkins Permissions

sudo usermod -aG docker jenkins
sudo usermod -aG microk8s jenkins
sudo systemctl restart jenkins

6️⃣ Access Jenkins

Open: http://<EC2-IP>:8080

Retrieve initial password:

cat /var/lib/jenkins/secrets/initialAdminPassword


Login and install suggested plugins.

7️⃣ Setup Jenkins Credentials

Go to Manage Jenkins → Credentials

Add two credentials:

GitHub → ID: git-creds

DockerHub → ID: dockerhub-credentials

8️⃣ Create First Pipeline (Hello World)

pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }
    }
}

9️⃣ Docker Build + Deploy Pipeline

Create a new pipeline named reactprofile-with-docker.
Update IMAGE_NAME with your DockerHub repository.

pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sufibaba6629/sufiprofile-reactapp'
        IMAGE_TAG  = "${IMAGE_NAME}:${BUILD_NUMBER}"
        Container  = "sufi-profile"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/sufyanahmadkamboh/sample-react-app.git', branch: 'main'
                sh 'ls -ltr'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_TAG} ${IMAGE_NAME}:latest"
                sh "docker images"
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${IMAGE_TAG}"
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }

        stage('Run Docker Container') {
            steps {
                sh "docker rm -f ${Container} || true"
                sh "docker run -d --name ${Container} -p 3000:80 ${IMAGE_TAG}"
                sh "docker image prune -f"
            }
        }
    }
}


✅ Access app at: http://<EC2-IP>:3000

🔟 Kubernetes Deployment Pipeline

Create a pipeline named reactprofile-on-Kubernetes.
Use Pipeline from SCM → GitHub Repo → Jenkinsfile-with-Kubernetes.

This will automatically deploy the app to Kubernetes.
Access at: http://<EC2-IP>:30080

1️⃣1️⃣ Configure GitHub Webhook (Auto Trigger)

Install plugins:

GitHub Integration Plugin

GitHub Plugin

Add GitHub credentials in Jenkins.

Add webhook in GitHub repository:

http://<YOUR_JENKINS_URL>/github-webhook/

🎯 Summary

Pipeline 1 → Hello World

Pipeline 2 → Build & Deploy React App with Docker

Pipeline 3 → Deploy React App on Kubernetes

Now you have a full CI/CD pipeline running with Jenkins → Docker → Kubernetes! 🚀