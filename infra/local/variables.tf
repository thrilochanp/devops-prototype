variable "cluster_name" {
  description = "Name of the kind cluster (shared with the Kubernetes learning track)"
  type        = string
  default     = "k8s-learning"
}

variable "node_image" {
  description = "kindest/node image pinned by digest, so a rebuild gets exactly the same Kubernetes"
  type        = string
  default     = "kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5"
}

variable "worker_count" {
  description = "Number of worker nodes next to the control plane"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "worker_count must be between 1 and 3 on a laptop."
  }
}

variable "gateway_host_port" {
  description = "Port on your Mac (127.0.0.1 only) that reaches the Envoy Gateway NodePort. 8080 is used by another project."
  type        = number
  default     = 8088
}

variable "gateway_node_port" {
  description = "NodePort the Envoy Gateway service is pinned to"
  type        = number
  default     = 30080
}

variable "kubeconfig_path" {
  description = "kubeconfig kind merges the cluster context into. Set explicitly so the provider never writes a credentials file into the repo."
  type        = string
  default     = "~/.kube/config"
}
