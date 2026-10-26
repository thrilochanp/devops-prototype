# Local Kubernetes for the prototype: 1 control plane + 1 worker.
# Port 8080 on 127.0.0.1 is mapped to NodePort 30080, where Envoy Gateway listens.
resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = var.gateway_node_port
        host_port      = var.gateway_host_port
        listen_address = "127.0.0.1"
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}
