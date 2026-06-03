resource "azurerm_monitor_autoscale_setting" "this" {

  name                = "${var.environment}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location

  target_resource_id = var.vmss_id

  profile {
    name = "default"

    capacity {
      default = tostring(var.default_instance_count)
      minimum = tostring(var.minimum_instance_count)
      maximum = tostring(var.maximum_instance_count)
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.vmss_id

        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"

        operator  = "GreaterThan"
        threshold = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.vmss_id

        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT10M"
        time_aggregation = "Average"

        operator  = "LessThan"
        threshold = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
