#!/bin/bash

set -e

echo "=== Multi-threaded Go App Deployment ==="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}===> $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Load .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check prerequisites
print_step "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { print_error "Docker is not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is not installed"; exit 1; }
command -v minikube >/dev/null 2>&1 || { print_error "minikube is not installed"; exit 1; }
print_success "All prerequisites found"

# Check if minikube is running
print_step "Checking Minikube status..."
if ! minikube status | grep -q "Running"; then
    print_step "Starting Minikube..."
    minikube start --driver=docker
fi
print_success "Minikube is running"

# Build Docker image
print_step "Building Docker image..."
docker build -t multithread-app:latest .
print_success "Docker image built"

# Load image into minikube
print_step "Loading image into Minikube..."
minikube image load multithread-app:latest
print_success "Image loaded into Minikube"

# Deploy to Kubernetes
print_step "Deploying to Kubernetes..."
kubectl apply -f kubernetes-deployment.yaml

# Wait for deployment
print_step "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/multithread-app -n multithread-app

# Get service URL
print_step "Getting service information..."
MINIKUBE_IP=$(minikube ip)
SERVICE_URL="http://${MINIKUBE_IP}:30080"

print_success "Deployment completed!"
echo ""
echo "=== Deployment Information ==="
echo "Service URL: ${SERVICE_URL}"
echo ""
echo "To test the application:"
echo "  curl ${SERVICE_URL}"
echo "  curl ${SERVICE_URL}/health"
echo ""
echo "To view pods:"
echo "  kubectl get pods -n multithread-app"
echo ""
echo "To view logs:"
echo "  kubectl logs -n multithread-app -l app=multithread-app"
echo ""
echo "To access via minikube service:"
echo "  minikube service multithread-app-service -n multithread-app"