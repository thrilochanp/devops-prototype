# Cloud-later target: AKS Free tier (no control-plane charge), one small node, a $5 budget.
# Destroy at the end of every session: terraform destroy -var-file=lab.tfvars

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.prefix
  sku_tier            = "Free"
  node_resource_group = "rg-${var.prefix}-nodes"

  oidc_issuer_enabled       = true # ready for Workload Identity + Key Vault later
  workload_identity_enabled = true

  default_node_pool {
    name            = "system"
    vm_size         = var.node_vm_size
    node_count      = 1
    os_disk_size_gb = 30
    os_disk_type    = "Managed"
    tags            = var.tags

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  tags = var.tags
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-${var.prefix}"
  resource_group_id = azurerm_resource_group.this.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = var.alert_emails
  }

  lifecycle {
    ignore_changes = [time_period] # start_date is computed once; don't churn it on every plan
  }
}
