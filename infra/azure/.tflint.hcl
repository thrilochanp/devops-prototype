config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Optional: add the azurerm ruleset with the version printed on
# https://github.com/terraform-linters/tflint-ruleset-azurerm/releases, then run `tflint --init`.
