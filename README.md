# Jenkins + Docker + MicroK8s on a Single Ubuntu EC2 — End-to-End Guide

This guide walks through provisioning an Ubuntu EC2 instance, installing Docker and MicroK8s (single-node Kubernetes), setting up Jenkins with JDK 21, and creating three Jenkins pipelines: a Hello World pipeline, a Dockerized React app build-and-deploy pipeline, and a Kubernetes deployment pipeline. We’ll finish by wiring up GitHub webhooks for automatic builds.

> **Note**: Opening all ports to the world is not recommended for production. Use least privilege security groups, restrict SSH, and add firewall rules as appropriate. Follow these steps in non-production or at your own risk.

---

## 1) Provision the EC2 Instance
Create an Ubuntu EC2 instance with the following minimum specs:
- Instance type: `t2.medium`
- Root volume: `50 GB`
- Security Group: Temporarily allow all inbound/outbound (`0.0.0.0/0`, all ports) for testing only.

After launch, connect to the instance via SSH:
```bash
ssh ubuntu@<EC2_PUBLIC_IP>
```

---

## 2) Install Docker and MicroK8s (Kubernetes)
```bash
sudo -i
apt update && apt install docker.io -y
apt install snap -y && snap install microk8s --classic
```

---

## 3) Configure kubectl Alias & Bash Completion
```bash
alias kubectl='microk8s kubectl'
source <(microk8s kubectl completion bash)
complete -F __start_kubectl kubectl

source ~/.bashrc
```

---

## 4) Install JDK 21 for Jenkins
```bash
sudo apt update
sudo apt install fontconfig openjdk-21-jre -y
java -version
```

---

## 5) Install Jenkins
```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc   https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]"   https://pkg.jenkins.io/debian-stable binary/ | sudo tee   /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install Jenkins -y
```

---

## 6) Grant Jenkins Access to Docker & MicroK8s
```bash
sudo usermod -aG docker jenkins
sudo usermod -aG microk8s jenkins
sudo systemctl restart jenkins
```

---

## 7) Access Jenkins & Initial Setup
Open Jenkins in your browser:
```
http://<EC2_PUBLIC_IP>:8080
```

Retrieve the initial admin password:
```bash
cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 8) Add GitHub & Docker Hub Credentials in Jenkins
- `git-creds`: GitHub username/password or personal access token  
- `dockerhub-credentials`: Docker Hub username and password

---

## 9) Create Your First Pipeline: Hello World
```groovy
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
```

---

## 10) Pipeline 2 — Build & Deploy React App with Docker
Create a Docker Hub repository (e.g., `sufibaba6629/sufiprofile-reactapp`).

Jenkinsfile:
```groovy
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
                echo "✅ Docker image built successfully"
                sh "docker images"
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${IMAGE_TAG}"
                sh "docker push ${IMAGE_NAME}:latest"
                echo "✅ Docker image pushed successfully"
            }
        }
        stage('Docker container creationg') {
            steps {
                sh "docker rm -f ${Container} || true"
                sh "docker run -d --name ${Container} -p 3000:80 ${IMAGE_TAG}"
                sh "docker image prune -f"
                echo "✅ Docker image pushed successfully"
            }
        }
    }
}
```

Access app:
```
http://<EC2_PUBLIC_IP>:3000
```

---

## 11) Pipeline 3 — Deploy to Kubernetes (MicroK8s)
- Create a new Pipeline job `reactprofile-on-Kubernetes`
- Select “Pipeline script from SCM”
- Set SCM to Git and provide repo URL
- Script Path: `jenkinsfile-with-Kubernetes`

App available at:
```
http://<EC2_PUBLIC_IP>:30080
```

---

## 12) Configure GitHub Webhook for Auto-Triggers
- Install **GitHub Integration Plugin** and **GitHub Plugin**
- Add GitHub credentials in Jenkins
- Add a webhook in your GitHub repo:
```
http://<YOUR_JENKINS_URL>/github-webhook/
```

---

## 13) Quick Troubleshooting
- If Docker fails in Jenkins: ensure `jenkins` user is in the `docker` group.
- If MicroK8s access fails: ensure group membership + kubeconfig access.
- If webhooks don’t fire: ensure Jenkins is accessible from GitHub (public IP/URL).

---
