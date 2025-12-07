#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

echo "======================================"
echo "  CI/CD Quick Start Setup"
echo "======================================"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { print_error "Docker not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl not installed"; exit 1; }
command -v minikube >/dev/null 2>&1 || { print_error "minikube not installed"; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "terraform not installed"; exit 1; }
command -v go >/dev/null 2>&1 || { print_error "Go not installed"; exit 1; }

print_success "All prerequisites found!"

# Create directory structure
print_step "Creating directory structure..."
mkdir -p .github/workflows
print_success "Directory structure created"

# Create .env file if not exists
if [ ! -f .env ]; then
    print_step "Creating .env file..."
    cp .env.example .env
    print_warning "Please edit .env file with your configuration"
fi

# Initialize git if not already
if [ ! -d .git ]; then
    print_step "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    print_success "Git repository initialized"
else
    print_success "Git repository already initialized"
fi

# Start minikube if not running
print_step "Checking Minikube status..."
if ! minikube status | grep -q "Running"; then
    print_step "Starting Minikube..."
    minikube start --driver=docker
    print_success "Minikube started"
else
    print_success "Minikube is already running"
fi

# Build and deploy
print_step "Building Docker image..."
docker build -t multithread-app:latest .
print_success "Docker image built"

print_step "Loading image to Minikube..."
minikube image load multithread-app:latest
print_success "Image loaded"

print_step "Initializing Terraform..."
terraform init
print_success "Terraform initialized"

echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure GitHub Actions:"
echo "   - Push to GitHub: git remote add origin YOUR_REPO_URL"
echo "   - Add secrets in GitHub Settings"
echo ""
echo "2. Setup Jenkins:"
echo "   - Run: ./jenkins-setup.sh"
echo "   - Follow on-screen instructions"
echo ""
echo "3. Deploy with Terraform:"
echo "   - Run: make tf-apply"
echo "   - Or: terraform apply"
echo ""
echo "4. Deploy to Kubernetes:"
echo "   - Run: make deploy"
echo "   - Or: ./deploy.sh"
echo ""
echo "Quick commands:"
echo "  make deploy          # Deploy to Kubernetes"
echo "  make tf-apply        # Apply Terraform"
echo "  make k8s-status      # Check deployment status"
echo "  make help            # Show all commands"
echo ""

# Offer to deploy now
read -p "Do you want to deploy to Kubernetes now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Deploying to Kubernetes..."
    kubectl apply -f kubernetes-deployment.yaml
    kubectl rollout status deployment/multithread-app -n multithread-app
    
    MINIKUBE_IP=$(minikube ip)
    echo ""
    print_success "Deployment complete!"
    echo "Access your application at: http://${MINIKUBE_IP}:30080"
    echo ""
    echo "Or run: minikube service multithread-app-service -n multithread-app"
fi

print_success "Setup script completed!"