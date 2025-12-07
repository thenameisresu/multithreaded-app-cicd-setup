# Follow this sequence and you'll have a complete CI/CD pipeline running! 

# Phase 1: Local Development & Testing
## Step 1: Make Scripts Executable
```bash
chmod +x deploy.sh jenkins-setup.sh quick-start.sh
```
## Step 2: Test Go Application Locally
```bash
# Build
go build -o multithread-app

# Run locally
./multithread-app

# In another terminal, test
curl http://localhost:8080
curl http://localhost:8080/health
```
## Step 3: Test Docker Build
```bash
# Build Docker image
docker build -t multithread-app:latest .

# Run Docker container
docker run -p 8080:8080 multithread-app:latest

# Test
curl http://localhost:8080/health
```
# Phase 2: Kubernetes Setup
## Step 4: Start Minikube
```bash
# Start Minikube
minikube start --driver=docker

# Verify
minikube status
kubectl cluster-info
```

## Step 5: Deploy to Kubernetes (Option A - Direct)
```bash
# Build and load image
docker build -t multithread-app:latest .
minikube image load multithread-app:latest

# Deploy
kubectl apply -f kubernetes-deployment.yaml

# Wait for deployment
kubectl rollout status deployment/multithread-app -n multithread-app

# Get service URL
minikube service multithread-app-service -n multithread-app --url

# Test
MINIKUBE_IP=$(minikube ip)
curl http://${MINIKUBE_IP}:30080
curl http://${MINIKUBE_IP}:30080/health
```

## Step 6: Deploy to Kubernetes (Option B - Using deploy.sh)
```bash
./deploy.sh
```
## Step 7: Deploy to Kubernetes (Option C - Using Makefile)
```bash
make deploy
```

# Phase 3: Terraform Setup
## Step 8: Initialize and Apply Terraform
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply (this will build Docker, deploy to K8s)
terraform apply

# View outputs
terraform output
```
## OR using Makefile:
```bash
make tf-init
make tf-plan
make tf-apply
```
# Phase 4: Jenkins Setup
## Step 9: Setup Jenkins
```bash
# Run Jenkins setup script
./jenkins-setup.sh
```
## Step 10: Configure Jenkins (Manual Steps)
1. Open http://localhost:8080
2. Enter initial admin password (shown in setup script)
3. Install suggested plugins + required plugins:
    - Go Plugin
    - Docker Pipeline
    - Kubernetes Plugin
4. Add credentials:
    - Docker Hub: ID = `docker-hub-credentials`
    - Kubeconfig: ID = `kubeconfig`
5. Configure Go tool: Name = `go-1.25`
6. Create new Pipeline job pointing to your Jenkinsfile

## Step 11: Test Jenkins Pipeline
```bash
# Trigger build manually in Jenkins UI
# Or push code to trigger automatically
git add .
git commit -m "Test Jenkins"
git push
```

# Phase 5: GitHub Actions Setup
## Step 12: Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial commit"
```
## Step 13: Create GitHub Repository and Push
```bash
# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/multithread-app.git
git branch -M main
git push -u origin main
```

## Step 14: Add GitHub Secrets
Go to GitHub repo → Settings → Secrets and variables → Actions
Add these secrets:
```bash
# Get base64 encoded kubeconfig
cat ~/.kube/config | base64 | pbcopy  # macOS
cat ~/.kube/config | base64 -w 0      # Linux

# Add as KUBECONFIG secret in GitHub
```
Secrets to add:
- DOCKER_USERNAME: `your-docker-username`
- DOCKER_PASSWORD: `your-docker-token`
- KUBECONFIG: `base64-encoded kubeconfig`

## Step 15: Test GitHub Actions
```bash
# Make a change and push
echo "# Test" >> README.md
git add .
git commit -m "Test GitHub Actions"
git push

# Check Actions tab in GitHub
```

# Complete Execution Sequence Summary
```bash
# 1. ONE-TIME SETUP
mkdir -p multithread-app/.github/workflows
cd multithread-app
# Create all files (go.mod, main.go, Dockerfile, etc.)
cp .env.example .env
chmod +x *.sh

# 2. LOCAL TESTING
go build -o multithread-app
./multithread-app  # Test locally

# 3. DOCKER TESTING
docker build -t multithread-app:latest .
docker run -p 8080:8080 multithread-app:latest

# 4. KUBERNETES DEPLOYMENT
minikube start --driver=docker
./deploy.sh  # OR make deploy

# 5. TERRAFORM DEPLOYMENT
terraform init
terraform apply  # OR make tf-apply

# 6. JENKINS SETUP
./jenkins-setup.sh
# Follow manual configuration steps
# Create pipeline job
# Test pipeline

# 7. GITHUB ACTIONS
git init
git add .
git commit -m "Initial commit"
git remote add origin YOUR_REPO_URL
git push -u origin main
# Add GitHub secrets
# Push changes to trigger Actions

# 8. VERIFY ALL SYSTEMS
make k8s-status
terraform output
# Check Jenkins dashboard
# Check GitHub Actions tab
```

# Daily Development Workflow
After initial setup, your daily workflow would be:
```bash
# 1. Make code changes
nano main.go

# 2. Test locally
go test ./...
go build -o multithread-app
./multithread-app

# 3. Commit and push
git add .
git commit -m "Your changes"
git push

# This automatically triggers:
# - GitHub Actions (builds, tests, deploys)
# - Jenkins Pipeline (if configured with webhooks)

# 4. Monitor deployments
kubectl get pods -n multithread-app
make k8s-logs

# 5. Access application
minikube service multithread-app-service -n multithread-app
```

# Quick Start Script (Automated)
If you want to automate most of this:
```bash
./quick-start.sh
```
This script will:
✅ Check prerequisites
✅ Create directories
✅ Create .env
✅ Initialize git
✅ Start Minikube
✅ Build Docker image
✅ Initialize Terraform
✅ Offer to deploy

# Troubleshooting Commands
```bash
# Check everything is running
make env-check
minikube status
kubectl get all -n multithread-app
terraform output

# View logs
make k8s-logs
kubectl logs -n multithread-app -l app=multithread-app

# Restart deployment
make k8s-restart

# Clean and redeploy
make clean-all
make deploy
```
