terraform {
  backend "azurerm" {
    resource_group_name  = "POC"
    storage_account_name = "tfstatepoc2026"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
