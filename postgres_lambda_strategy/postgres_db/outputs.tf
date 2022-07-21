output "bastion_id" {
  description = "Instance ID of the bastion"
  value       = module.bastion.id
}

output "db_config" {
  description = "The config for the example db"
  sensitive   = true
  value = {
    "host" = module.db.cluster_endpoint
    "port" = module.db.cluster_port
    "user" = module.db.cluster_master_username
    "pass" = module.db.cluster_master_password
  }
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "security_group_id" {
  value = module.vpc.default_security_group_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
