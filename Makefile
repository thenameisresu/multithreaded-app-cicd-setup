.PHONY: build run test docker-build docker-run k8s-deploy k8s-delete tf-init tf-apply tf-destroy clean

# Variables
APP_NAME=multithread-app
DOCKER_IMAGE=$(APP_NAME):latest
K8S_NAMESPACE=multithread-app

# Build Go application
build:
	@echo "Building Go application..."
	go build -o $(APP_NAME)

# Run locally
run: build
	@echo "Running application..."
	./$(APP_NAME)

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Docker commands
docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .

docker-run: docker-build
	@echo "Running Docker container..."
	docker run -p 8080:8080 --rm $(DOCKER_IMAGE)

docker-push:
	@echo "Pushing Docker image..."
	docker push $(DOCKER_IMAGE)

# Kubernetes commands
k8s-deploy: docker-build
	@echo "Loading image to Minikube..."
	minikube image load $(DOCKER_IMAGE)
	@echo "Deploying to Kubernetes..."
	kubectl apply -f kubernetes-deployment.yaml
	@echo "Waiting for deployment..."
	kubectl rollout status deployment/$(APP_NAME) -n $(K8S_NAMESPACE)

k8s-delete:
	@echo "Deleting Kubernetes resources..."
	kubectl delete -f kubernetes-deployment.yaml

k8s-logs:
	@echo "Fetching logs..."
	kubectl logs -n $(K8S_NAMESPACE) -l app=$(APP_NAME) --tail=100

k8s-status:
	@echo "Getting deployment status..."
	kubectl get all -n $(K8S_NAMESPACE)

k8s-service:
	@echo "Opening service in browser..."
	minikube service $(APP_NAME)-service -n $(K8S_NAMESPACE)

# Terraform commands
tf-init:
	@echo "Initializing Terraform..."
	terraform init

tf-plan: tf-init
	@echo "Planning Terraform changes..."
	terraform plan

tf-apply: tf-init docker-build
	@echo "Applying Terraform configuration..."
	minikube image load $(DOCKER_IMAGE)
	terraform apply -auto-approve

tf-destroy:
	@echo "Destroying Terraform resources..."
	terraform destroy -auto-approve

# Utility commands
clean:
	@echo "Cleaning up..."
	rm -f $(APP_NAME)
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

minikube-start:
	@echo "Starting Minikube..."
	minikube start --driver=docker

minikube-stop:
	@echo "Stopping Minikube..."
	minikube stop

minikube-delete:
	@echo "Deleting Minikube cluster..."
	minikube delete

# Full deployment
deploy: docker-build k8s-deploy
	@echo "Deployment complete!"
	@echo "Access the application at: http://$$(minikube ip):30080"

# Help
help:
	@echo "Available targets:"
	@echo "  build         - Build Go application"
	@echo "  run           - Run application locally"
	@echo "  test          - Run tests"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-run    - Run Docker container"
	@echo "  k8s-deploy    - Deploy to Kubernetes"
	@echo "  k8s-delete    - Delete Kubernetes resources"
	@echo "  k8s-logs      - View application logs"
	@echo "  k8s-status    - Show deployment status"
	@echo "  k8s-service   - Open service in browser"
	@echo "  tf-init       - Initialize Terraform"
	@echo "  tf-apply      - Apply Terraform configuration"
	@echo "  tf-destroy    - Destroy Terraform resources"
	@echo "  deploy        - Full deployment to Kubernetes"
	@echo "  clean         - Clean build artifacts"