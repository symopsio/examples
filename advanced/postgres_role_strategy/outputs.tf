output "bastion_id" {
  description = "Instance ID of the bastion if enabled"
  value       = var.db_enabled ? module.db[0].bastion_id : ""
}

output "db_config" {
  description = "The config for the example db if enabled"
  sensitive   = true
  value       = var.db_enabled ? module.db[0].db_config : {}
}
