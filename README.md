# multithreaded-app-cicd-setup
This repository demonstrates a complete CI/CD pipeline for a multithreaded Go application leveraging goroutines and channels for high-performance concurrency. It includes production-ready configurations for building, testing, containerization, orchestration, and infrastructure provisioning.

## Complete Kubernetes Setup Guide for macOS

### Prerequisites Check
```bash
# Uninstall Docker Desktop
# Quit Docker Desktop first, then:
sudo /Applications/Docker.app/Contents/MacOS/uninstall

# Remove Docker files
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/.docker

# Remove CLI symlinks
sudo rm -rf /usr/local/bin/docker
sudo rm -rf /usr/local/bin/docker-compose
sudo rm -rf /usr/local/bin/docker-credential-desktop

# Uninstall Jenkins
# If installed via Homebrew:
brew services stop jenkins-lts
brew uninstall jenkins-lts

# Remove Jenkins data
rm -rf ~/.jenkins
sudo rm -rf /var/log/jenkins
sudo rm -rf /Library/LaunchDaemons/org.jenkins-ci.plist

# Uninstall Terraform
# If installed via Homebrew:
brew uninstall terraform

# Or manually:
sudo rm -rf /usr/local/bin/terraform
rm -rf ~/.terraform.d

# Uninstall Kubernetes (kubectl, minikube, etc.)
# Uninstall kubectl
brew uninstall kubectl
sudo rm -rf /usr/local/bin/kubectl

# Uninstall minikube if installed
minikube delete --all
brew uninstall minikube
rm -rf ~/.minikube

# Remove kube configs
rm -rf ~/.kube

# Check if tools are installed
which docker
which kubectl
which minikube

# If not installed, install them:
# Install Docker Desktop
# Install via Homebrew
brew install --cask docker

# After installation, open Docker Desktop from Applications
# Wait for Docker to start completely
# install Docker Desktop from https://docs.docker.com/desktop/setup/install/mac-install/

# Install Jenkins
# Install Jenkins LTS
brew install jenkins-lts

# Start Jenkins
brew services start jenkins-lts

# Jenkins will be available at: http://localhost:8080
# Get initial admin password:
cat ~/.jenkins/secrets/initialAdminPassword

# Install Terraform
brew install terraform

# Verify installation
terraform version

# Install Kubernetes Tools
# Install kubectl
brew install kubectl

# Install minikube (local Kubernetes cluster)
brew install minikube

# Start minikube
minikube start --driver=docker

# Verify
kubectl cluster-info
```

### Step 1: Start Docker Desktop

- Open Docker Desktop from Applications
- Wait until Docker is running (whale icon in menu bar should be stable)
- Verify Docker is running:
    ```bash
    docker info
    docker ps
    ```

### Step 2: Start Minikube Cluster

```bash
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=4 --memory=4096

# Verify cluster is running
minikube status
```
**Output:**
```txt
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

#### Verify kubectl connection:
```bash
kubectl cluster-info
```
**Output:**
```txt
Kubernetes control plane is running at https://127.0.0.1:53768
CoreDNS is running at https://127.0.0.1:53768/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```bash
kubectl get nodes
```
**Output**
```txt
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   4m51s   v1.34.0
```

### Step 3: Create Namespace
```bash
# Create dedicated namespace for your app
kubectl create namespace multithread-app

# Verify namespace created
kubectl get namespaces

# Set as default namespace (optional but recommended)
kubectl config set-context --current --namespace=multithread-app

# Verify current namespace
kubectl config view --minify | grep namespace:
```

### Step 4: Create Docker Registry Secret
This allows Kubernetes to pull images from your Docker Hub account.
```bash
# Create Docker registry secret
kubectl create secret docker-registry docker-credentials \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<docker-username> \
  --docker-password=<docker-password> \
  --docker-email=<docker-email> \
  --namespace=multithread-app

# Verify secret created
kubectl get secrets -n multithread-app

# View secret details (base64 encoded)
kubectl describe secret docker-credentials -n multithread-app
```

### Step 5: Build and Push Docker Image
```bash
# Navigate to your project directory
cd multithread-app

# Build Docker image
docker build -t udaykishoreresu/multithread-app:latest .

# Tag with version (optional)
docker tag udaykishoreresu/multithread-app:latest \
  udaykishoreresu/multithread-app:v1.0.0

# Login to Docker Hub
docker login -u udaykishoreresu -p 9876543210

# Push to Docker Hub
docker push udaykishoreresu/multithread-app:latest
docker push udaykishoreresu/multithread-app:v1.0.0

# Verify image on Docker Hub
docker search udaykishoreresu/multithread-app
```

### Step 6: Update Kubernetes Deployment 
If you want to use the Docker secret we created, update

[Deployment](kubernetes-deployment.yaml)

### Step 7: Deploy Application to Kubernetes
After creating the kubernetes-deployment.yaml file, run the deployment:
```bash
# Apply the deployment
kubectl apply -f kubernetes-deployment.yaml

or

./deploy.sh

or 
# use the Makefile:
make deploy

# Expected output:
# deployment.apps/multithread-app created
# service/multithread-app-service created

# Watch deployment progress
kubectl get deployments -n multithread-app -w

# Stop watching with Ctrl+C when ready

# Check deployment status
kubectl get deployments -n multithread-app

# Expected output:
# NAME              READY   UP-TO-DATE   AVAILABLE   AGE
# multithread-app   3/3     3            3           1m
```
