resource "azurerm_linux_virtual_machine_scale_set" "this" {

  name                = "${var.environment}-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku       = "Standard_D2s_v3"
  instances = var.instance_count

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "vmssnic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      load_balancer_backend_address_pool_ids = [
        var.backend_pool_id
      ]
    }
  }

  custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install nginx -y
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>Terraform VM - ${var.environment}</title></head>
<body>
  <h1>Terraform Azure VM - ${var.environment}</h1>
  <p><b>DB Username:</b> ${var.db_username}</p>
  <p><b>DB Password:</b> ${var.db_password}</p>
  <p><b>Admin Username:</b> ${var.admin_username}</p>
  <p><b>Admin Password:</b> ${var.admin_password}</p>
</body>
</html>
HTML
systemctl enable nginx
systemctl restart nginx
EOF
  )
}
