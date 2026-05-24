output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "The name of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "public_ip_address" {
  description = "The public IP address of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
}

output "private_ip_address" {
  description = "The private IP address of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.private_ip_addresses
}

output "resource_group_name" {
  description = "The resource group name"
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.rg.location
}

output "admin_username" {
  description = "The admin username for the VM"
  value       = azurerm_linux_virtual_machine.vm.admin_username
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${azurerm_linux_virtual_machine.vm.admin_username}@${azurerm_linux_virtual_machine.vm.public_ip_address}"
}