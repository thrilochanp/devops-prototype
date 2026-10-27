# Local Kubernetes shared by the DevOps prototype and the Kubernetes learning track:
# 1 control plane + var.worker_count workers.
# 127.0.0.1:var.gateway_host_port on the Mac is mapped to NodePort 30080, where Envoy Gateway listens.
#
# Every attribute of kind_cluster forces replacement, and the provider has no import support:
# changing anything here (image, nodes, ports) means destroy and recreate.
resource "kind_cluster" "this" {
  name            = var.cluster_name
  node_image      = var.node_image
  wait_for_ready  = true
  kubeconfig_path = pathexpand(var.kubeconfig_path)

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

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}
