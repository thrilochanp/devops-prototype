variable "subscription_id" {
  description = "Azure subscription to deploy into (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "prefix" {
  description = "Short name used in every resource name"
  type        = string
  default     = "devopsproto"
}

variable "node_vm_size" {
  description = "Node size; check availability with: az vm list-skus -l <region> --size Standard_B2 -o table"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API, e.g. [\"203.0.113.10/32\"] (curl -s ifconfig.me)"
  type        = list(string)
}

variable "budget_amount" {
  description = "Monthly budget in the billing currency; alerts fire at 50/80/100%"
  type        = number
  default     = 5
}

variable "alert_emails" {
  description = "Who gets budget alerts"
  type        = list(string)
}

variable "tags" {
  description = "Tags on every resource"
  type        = map(string)
  default = {
    project = "devops-prototype"
    ttl     = "same-day"
    owner   = "platform"
  }
}
