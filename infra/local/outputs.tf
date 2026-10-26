output "cluster_name" {
  value = kind_cluster.this.name
}

output "api_endpoint" {
  value = kind_cluster.this.endpoint
}

output "gateway_url_example" {
  value = "http://orders-dev.localtest.me:${var.gateway_host_port}/orders"
}
