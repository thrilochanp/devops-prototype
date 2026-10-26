output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "get_credentials" {
  description = "Run this to point kubectl at the cluster"
  value       = "az aks get-credentials -g ${azurerm_resource_group.this.name} -n ${azurerm_kubernetes_cluster.this.name} --overwrite-existing"
}
