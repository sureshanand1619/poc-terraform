variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_ssh_ip" {
  type    = string
  default = "*"
}
