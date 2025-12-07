pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_IMAGE = 'udaykishoresresu/multithread-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_LATEST = 'latest'
        
        // Credentials from Jenkins credential store
        DOCKER_CREDENTIALS = credentials('docker-hub-credentials')
        KUBECONFIG = credentials('kubeconfig-credentials')
        
        // Kubernetes configuration
        K8S_NAMESPACE = 'multithread-app'
        K8S_DEPLOYMENT = 'multithread-app'
        
        // Application configuration
        APP_NAME = 'multithread-app'
    }
    
    options {
        // Keep only last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // Add timestamps to console output
        timestamps()
        
        // Timeout for entire pipeline
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from SCM...'
                checkout scm
                
                script {
                    // Get git commit info
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_MSG = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()
                }
                
                echo "✅ Checked out commit: ${env.GIT_COMMIT_SHORT}"
                echo "📝 Commit message: ${env.GIT_COMMIT_MSG}"
            }
        }
        
        stage('Build Go Application') {
            steps {
                echo '🔨 Building Go application...'
                sh '''
                    # Display Go version
                    go version
                    
                    # Download dependencies
                    echo "📦 Downloading Go dependencies..."
                    go mod download
                    
                    # Build the application
                    echo "🔧 Building application..."
                    go build -v -o app
                    
                    # Check if binary was created
                    if [ -f "app" ]; then
                        echo "✅ Binary created successfully"
                        ls -lh app
                    else
                        echo "❌ Binary creation failed"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '🧪 Running tests...'
                sh '''
                    # Run tests with verbose output
                    go test -v ./...
                    
                    # Run tests with coverage
                    go test -v -coverprofile=coverage.out ./...
                    
                    # Display coverage
                    go tool cover -func=coverage.out
                '''
            }
            post {
                success {
                    echo '✅ All tests passed!'
                }
                failure {
                    echo '❌ Tests failed!'
                }
            }
        }
        
        stage('Code Quality Check') {
            steps {
                echo '🔍 Running code quality checks...'
                sh '''
                    # Format check
                    echo "Checking code formatting..."
                    gofmt -l . || true
                    
                    # Vet check
                    echo "Running go vet..."
                    go vet ./... || true
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    sh """
                        # Build image with build number tag
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        
                        # Tag with latest
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${DOCKER_LATEST}
                        
                        # Tag with git commit
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}
                        
                        # List images
                        echo "📋 Built images:"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
                echo "✅ Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                echo '🔒 Scanning Docker image for vulnerabilities...'
                script {
                    // Optional: Add docker scan or trivy scan here
                    sh """
                        echo "Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker inspect ${DOCKER_IMAGE}:${DOCKER_TAG} --format='{{.Size}}' | \
                        awk '{print "Image size: " \$1/1024/1024 " MB"}'
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing Docker image to Docker Hub...'
                script {
                    sh """
                        # Login to Docker Hub
                        echo "🔐 Logging in to Docker Hub..."
                        echo ${DOCKER_CREDENTIALS_PSW} | docker login -u ${DOCKER_CREDENTIALS_USR} --password-stdin
                        
                        # Push all tags
                        echo "⬆️  Pushing ${DOCKER_IMAGE}:${DOCKER_TAG}..."
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        echo "⬆️  Pushing ${DOCKER_IMAGE}:${DOCKER_LATEST}..."
                        docker push ${DOCKER_IMAGE}:${DOCKER_LATEST}
                        
                        echo "⬆️  Pushing ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}..."
                        docker push ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}
                        
                        echo "✅ All images pushed successfully!"
                    """
                }
            }
            post {
                success {
                    echo "✅ Docker images pushed to Docker Hub"
                    echo "📦 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    echo "📦 ${DOCKER_IMAGE}:${DOCKER_LATEST}"
                }
                failure {
                    echo "❌ Failed to push Docker images"
                }
            }
        }
        
        stage('Verify Kubernetes Cluster') {
            steps {
                echo '☸️  Verifying Kubernetes cluster connection...'
                sh """
                    # Set kubeconfig
                    export KUBECONFIG=${KUBECONFIG}
                    
                    # Check cluster info
                    echo "📊 Cluster information:"
                    kubectl cluster-info
                    
                    # Check nodes
                    echo "🖥️  Cluster nodes:"
                    kubectl get nodes
                    
                    # Check namespace
                    echo "📁 Checking namespace..."
                    kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}
                """
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to Kubernetes...'
                script {
                    sh """
                        # Set kubeconfig
                        export KUBECONFIG=${KUBECONFIG}
                        
                        # Apply deployment
                        echo "📝 Applying Kubernetes manifests..."
                        kubectl apply -f k8s/deployment.yaml
                        
                        # Update image to use specific build tag
                        echo "🔄 Updating deployment with new image..."
                        kubectl set image deployment/${K8S_DEPLOYMENT} \
                            ${K8S_DEPLOYMENT}=${DOCKER_IMAGE}:${DOCKER_TAG} \
                            -n ${K8S_NAMESPACE}
                        
                        # Wait for rollout to complete
                        echo "⏳ Waiting for deployment to complete..."
                        kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=5m
                        
                        # Get deployment status
                        echo "📊 Deployment status:"
                        kubectl get deployment ${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}
                        
                        # Get pods
                        echo "🔍 Pod status:"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT}
                        
                        # Get services
                        echo "🌐 Services:"
                        kubectl get services -n ${K8S_NAMESPACE}
                    """
                }
            }
            post {
                success {
                    echo '✅ Deployment successful!'
                }
                failure {
                    echo '❌ Deployment failed!'
                    sh """
                        export KUBECONFIG=${KUBECONFIG}
                        echo "📋 Recent events:"
                        kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -20
                        
                        echo "📋 Pod logs:"
                        kubectl logs -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT} --tail=50
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    
                    # Check if pods are ready
                    echo "🔍 Checking pod readiness..."
                    kubectl wait --for=condition=ready pod -l app=${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=300s
                    
                    # Get pod details
                    kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT} -o wide
                    
                    # Check service endpoints
                    echo "🌐 Service endpoints:"
                    kubectl get endpoints -n ${K8S_NAMESPACE}
                    
                    # Test health endpoint (if accessible)
                    echo "🏥 Testing health endpoint..."
                    POD_NAME=\$(kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT} -o jsonpath='{.items[0].metadata.name}')
                    kubectl exec \$POD_NAME -n ${K8S_NAMESPACE} -- wget -q -O- http://localhost:8080/health || echo "Health check failed"
                """
            }
        }
        
        stage('Smoke Test') {
            steps {
                echo '🔥 Running smoke tests...'
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    
                    echo "🧪 Running smoke tests on deployed application..."
                    
                    # Get pod name
                    POD_NAME=\$(kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT} -o jsonpath='{.items[0].metadata.name}')
                    
                    # Test root endpoint
                    echo "Testing root endpoint..."
                    kubectl exec \$POD_NAME -n ${K8S_NAMESPACE} -- wget -q -O- http://localhost:8080/ || echo "Root endpoint test failed"
                    
                    # Test health endpoint
                    echo "Testing health endpoint..."
                    kubectl exec \$POD_NAME -n ${K8S_NAMESPACE} -- wget -q -O- http://localhost:8080/health || echo "Health endpoint test failed"
                    
                    echo "✅ Smoke tests completed"
                """
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Logout from Docker
                docker logout || true
                
                # Clean up old Docker images (keep last 3 builds)
                docker images | grep ${DOCKER_IMAGE} | tail -n +4 | awk '{print $3}' | xargs -r docker rmi -f || true
            '''
            
            // Clean workspace
            cleanWs()
        }
        
        success {
            echo '✅ ========================================='
            echo '✅ Pipeline executed successfully!'
            echo '✅ ========================================='
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "🚀 Deployed to Kubernetes namespace: ${K8S_NAMESPACE}"
            echo "⏱️  Build Duration: ${currentBuild.durationString}"
            echo '✅ ========================================='
        }
        
        failure {
            echo '❌ ========================================='
            echo '❌ Pipeline failed!'
            echo '❌ ========================================='
            echo "❌ Build Number: ${env.BUILD_NUMBER}"
            echo "❌ Failed Stage: ${env.STAGE_NAME}"
            echo "⏱️  Build Duration: ${currentBuild.durationString}"
            echo '❌ ========================================='
        }
        
        unstable {
            echo '⚠️  Pipeline completed with warnings'
        }
        
        aborted {
            echo '🛑 Pipeline was aborted'
        }
    }
}