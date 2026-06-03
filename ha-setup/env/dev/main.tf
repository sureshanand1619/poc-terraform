data "azurerm_key_vault" "kv" {
  name                = "tf-kv-2026"
  resource_group_name = "POC"
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "db_username" {
  name         = "db-username"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

module "rg" {
  source = "../../modules/rg"

  resource_group_name = var.resource_group_name
  location            = var.location
}

module "network" {
  source = "../../modules/network"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  environment         = var.environment
  vnet_cidr           = var.vnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "nsg" {
  source = "../../modules/nsg"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  environment    = var.environment
  allowed_ssh_ip = var.allowed_ssh_ip
}


resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = module.network.private_subnet_id
  network_security_group_id = module.nsg.nsg_id
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  environment = var.environment
}

module "vmss" {
  source = "../../modules/vmss"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  environment     = var.environment
  subnet_id       = module.network.private_subnet_id
  backend_pool_id = module.loadbalancer.backend_pool_id

  admin_username = var.admin_username
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  db_username    = data.azurerm_key_vault_secret.db_username.value
  db_password    = data.azurerm_key_vault_secret.db_password.value
  instance_count = var.instance_count
}

module "autoscale" {
  source = "../../modules/autoscale"

  environment         = var.environment
  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  vmss_id = module.vmss.vmss_id

  default_instance_count = var.instance_count
  minimum_instance_count = var.min_instance_count
  maximum_instance_count = var.max_instance_count

  scale_out_cpu_threshold = var.scale_out_cpu_threshold
  scale_in_cpu_threshold  = var.scale_in_cpu_threshold
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location

  environment = var.environment
}

module "alerts" {
  source = "../../modules/alerts"

  resource_group_name = module.rg.resource_group_name

  environment = var.environment
  alert_email = var.alert_email
}

output "resource_group_name" {
  value = module.rg.resource_group_name
}

output "load_balancer_public_ip" {
  value = module.loadbalancer.public_ip
}

output "vmss_name" {
  value = module.vmss.vmss_name
}

output "log_analytics_workspace" {
  value = module.monitoring.workspace_name
}

output "autoscale_setting" {
  value = module.autoscale.autoscale_setting_name
}
