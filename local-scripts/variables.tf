variable "location" {
  default = "East US 2"
}

variable "resource_group_name" {
  default = "terraform-vm-rg"
}

variable "vm_name" {
  default = "terraformvm"
}

variable "admin_username" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}