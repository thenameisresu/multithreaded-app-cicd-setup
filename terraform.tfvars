# Application Configuration
app_name    = "multithread-app"
app_version = "latest"
namespace   = "multithread-app"

# Deployment Configuration
replicas = 3

# Resource Configuration
cpu_request    = "250m"
cpu_limit      = "500m"
memory_request = "64Mi"
memory_limit   = "128Mi"

# Network Configuration
container_port = 8080
node_port      = 30080

# Infrastructure Configuration
docker_host      = "unix:///var/run/docker.sock"
kubeconfig_path  = "~/.kube/config"