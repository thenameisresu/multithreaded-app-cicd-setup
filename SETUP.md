# Complete CI/CD Setup Guide

## Project Structure

```
multithread-app/
├── .github/
│   └── workflows/
│       ├── ci.yml              # GitHub Actions CI/CD
│       └── terraform.yml        # Terraform automation
├── main.go
├── go.mod
├── Dockerfile
├── kubernetes-deployment.yaml
├── Jenkinsfile
├── main.tf                      # Terraform main config
├── terraform.tfvars            # Terraform variables
├── jenkins-setup.sh            # Jenkins setup script
├── deploy.sh
├── Makefile
├── .env
├── .env.example
└── .gitignore
```

---

## 1. GitHub Actions Setup

### Step 1: Create GitHub Repository
```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit"

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/multithread-app.git
git branch -M main
git push -u origin main
```

### Step 2: Add GitHub Secrets
Go to: **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub access token
- `KUBECONFIG`: Base64 encoded kubeconfig file

```bash
# Create base64 encoded kubeconfig
cat ~/.kube/config | base64 | pbcopy  # macOS
# Paste this as KUBECONFIG secret
```

### Step 3: Enable GitHub Actions
- Go to **Actions** tab in your repository
- Enable workflows
- Push changes to trigger the pipeline

### Step 4: Monitor Workflows
- Navigate to **Actions** tab
- View running/completed workflows
- Check logs for each step

---

## 2. Jenkins Setup

### Step 1: Install and Configure Jenkins
```bash
# Make setup script executable
chmod +x jenkins-setup.sh

# Run setup
./jenkins-setup.sh
```

### Step 2: Access Jenkins
1. Open http://localhost:8080
2. Use initial admin password (shown in setup script output)
3. Install suggested plugins

### Step 3: Install Required Plugins
**Manage Jenkins → Manage Plugins → Available**

Required plugins:
- Go Plugin
- Docker Pipeline
- Kubernetes Plugin
- Pipeline: Stage View Plugin
- Blue Ocean (optional, for better UI)
- Slack Notification Plugin (optional)

### Step 4: Configure Global Tools
**Manage Jenkins → Global Tool Configuration**

#### Go Installation
- Add Go
- Name: `go-1.21`
- Check "Install automatically"
- Version: Go 1.21

#### Docker
- Usually auto-detected if Docker is installed

### Step 5: Add Credentials
**Manage Jenkins → Manage Credentials → System → Global credentials**

#### Docker Hub Credentials
- Kind: Username with password
- Scope: Global
- Username: your-docker-username
- Password: your-docker-access-token
- ID: `docker-hub-credentials`

#### Kubeconfig
- Kind: Secret file
- Scope: Global
- File: Upload `~/.kube/config`
- ID: `kubeconfig`

### Step 6: Create Pipeline Job
1. **New Item** → Enter name: `multithread-app-pipeline`
2. Select **Pipeline** → OK
3. Configure:
   - **Description**: Multi-threaded Go App CI/CD
   - **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
   - **Pipeline**:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: your-git-repo-url
     - Branch: */main
     - Script Path: Jenkinsfile

### Step 7: Test Pipeline
```bash
# Trigger build manually first
# Jenkins → Your Pipeline → Build Now

# Or push to repository
git add .
git commit -m "Test Jenkins pipeline"
git push
```

---

## 3. Terraform Setup

### Step 1: Initialize Terraform
```bash
# Navigate to project directory
cd multithread-app

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt
```

### Step 2: Review Plan
```bash
# See what Terraform will create
terraform plan

# Save plan to file
terraform plan -out=tfplan
```

### Step 3: Apply Configuration
```bash
# Apply with auto-approve
terraform apply -auto-approve

# Or review before applying
terraform apply
```

### Step 4: Verify Deployment
```bash
# View Terraform outputs
terraform output

# Check Kubernetes resources
kubectl get all -n multithread-app
```

### Step 5: Modify Configuration
```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change values (e.g., replicas = 5)
replicas = 5

# Apply changes
terraform apply
```

### Step 6: Destroy Resources
```bash
# When you want to tear down
terraform destroy

# Or use Makefile
make tf-destroy
```

---

## 4. Integration Testing

### Test GitHub Actions
```bash
# Make a change
echo "# Update" >> README.md

# Commit and push
git add .
git commit -m "Test GitHub Actions"
git push

# Check Actions tab in GitHub
```

### Test Jenkins
```bash
# Push to trigger Jenkins
git add .
git commit -m "Test Jenkins pipeline"
git push

# Or trigger manually in Jenkins UI
```

### Test Terraform
```bash
# Test plan
make tf-plan

# Apply changes
make tf-apply

# Check deployment
kubectl get pods -n multithread-app
```

### Test Complete Pipeline
```bash
# Full deployment using Makefile
make deploy

# Or using deploy script
./deploy.sh
```

---

## 5. Monitoring and Troubleshooting

### GitHub Actions
```bash
# View workflow runs
# GitHub → Actions tab

# Download logs
# Click on workflow run → Download logs
```

### Jenkins
```bash
# View console output
# Jenkins → Job → Build Number → Console Output

# View Jenkins logs
tail -f /usr/local/var/log/jenkins/jenkins.log

# Restart Jenkins
brew services restart jenkins-lts
```

### Terraform
```bash
# Show current state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show kubernetes_deployment.app

# Debug mode
TF_LOG=DEBUG terraform apply
```

### Kubernetes
```bash
# Check pods
kubectl get pods -n multithread-app

# View logs
kubectl logs -n multithread-app -l app=multithread-app

# Describe pod
kubectl describe pod POD_NAME -n multithread-app

# Get events
kubectl get events -n multithread-app --sort-by='.lastTimestamp'
```

---

## 6. Common Issues and Solutions

### Issue: GitHub Actions fails on Docker push
**Solution**: Check Docker Hub credentials in GitHub Secrets

### Issue: Jenkins can't connect to Kubernetes
**Solution**: Verify kubeconfig credential is correctly uploaded

### Issue: Terraform can't find Docker image
**Solution**: Build image first: `docker build -t multithread-app:latest .`

### Issue: Pods in CrashLoopBackOff
**Solution**: Check logs: `kubectl logs -n multithread-app POD_NAME`

### Issue: Service not accessible
**Solution**: Use minikube service: `minikube service multithread-app-service -n multithread-app`

---

## 7. Best Practices

### For GitHub Actions
- Use branch protection rules
- Require status checks before merging
- Use environments for staging/production
- Store secrets securely

### For Jenkins
- Use declarative pipeline syntax
- Implement proper error handling
- Clean up workspace after builds
- Use shared libraries for common tasks

### For Terraform
- Use remote state for team collaboration
- Enable state locking
- Use workspaces for environments
- Version your Terraform code
- Review plans before applying

### For Kubernetes
- Use namespaces for isolation
- Set resource limits
- Implement health checks
- Use ConfigMaps for configuration
- Use Secrets for sensitive data

---

## 8. Quick Reference

### GitHub Actions Commands
```bash
# View workflow runs
gh run list

# View specific run
gh run view RUN_ID

# Re-run failed jobs
gh run rerun RUN_ID
```

### Jenkins Commands
```bash
# Restart Jenkins
brew services restart jenkins-lts

# View logs
tail -f /usr/local/var/log/jenkins/jenkins.log
```

### Terraform Commands
```bash
# Quick deployment
make tf-apply

# Quick destruction
make tf-destroy

# View outputs
make tf-output
```

### Kubectl Commands
```bash
# Quick status
make k8s-status

# View logs
make k8s-logs

# Port forward
make k8s-port-forward
```

---

## Support

For issues or questions:
1. Check logs first
2. Verify credentials and configurations
3. Ensure all services are running
4. Review this guide for troubleshooting steps