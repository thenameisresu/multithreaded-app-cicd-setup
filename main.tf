terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Provider Configuration
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "docker" {
  host = var.docker_host
}

# Variables
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "multithread-app"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "latest"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "multithread-app"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 3
}

variable "docker_host" {
  description = "Docker daemon host"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "node_port" {
  description = "NodePort for service"
  type        = number
  default     = 30080
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "64Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "128Mi"
}

# Docker Image
resource "docker_image" "app" {
  name = "${var.app_name}:${var.app_version}"
  build {
    context    = "${path.module}"
    dockerfile = "Dockerfile"
    tag        = ["${var.app_name}:${var.app_version}"]
    label = {
      app     = var.app_name
      version = var.app_version
    }
  }
}

# Kubernetes Namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      managed-by  = "terraform"
      environment = terraform.workspace
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    APP_NAME = var.app_name
    APP_PORT = tostring(var.container_port)
    LOG_LEVEL = "info"
  }
}

# Secret for sensitive data (example)
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "${var.app_name}-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    # Add your secrets here (base64 encoded)
    # api_key = base64encode("your-api-key")
  }

  type = "Opaque"
}

# Kubernetes Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app         = var.app_name
      version     = var.app_version
      managed-by  = "terraform"
      environment = terraform.workspace
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = var.app_version
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = tostring(var.container_port)
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name              = var.app_name
          image             = docker_image.app.name
          image_pull_policy = "Never" # For Minikube

          port {
            name           = "http"
            container_port = var.container_port
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        restart_policy = "Always"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
  }

  depends_on = [
    kubernetes_config_map.app_config,
    docker_image.app
  ]
}

# Kubernetes Service
resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app        = var.app_name
      managed-by = "terraform"
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    type = "NodePort"

    port {
      name        = "http"
      port        = 80
      target_port = var.container_port
      node_port   = var.node_port
      protocol    = "TCP"
    }

    session_affinity = "ClientIP"
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# Outputs
output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "deployment_name" {
  description = "Deployment name"
  value       = kubernetes_deployment.app.metadata[0].name
}

output "service_name" {
  description = "Service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "service_url" {
  description = "Service URL (use with minikube)"
  value       = "http://$(minikube ip):${var.node_port}"
}

output "replicas" {
  description = "Number of replicas"
  value       = var.replicas
}

output "docker_image" {
  description = "Docker image name"
  value       = docker_image.app.name
}

output "pod_selector" {
  description = "Pod selector for kubectl commands"
  value       = "app=${var.app_name}"
}