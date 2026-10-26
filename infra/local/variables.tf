variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "devops-proto"
}

variable "node_image" {
  description = "kindest/node image; null uses the default for your kind version"
  type        = string
  default     = null
}

variable "gateway_host_port" {
  description = "Port on your laptop that reaches the Envoy Gateway NodePort"
  type        = number
  default     = 8080
}

variable "gateway_node_port" {
  description = "NodePort the Envoy Gateway service is pinned to"
  type        = number
  default     = 30080
}
