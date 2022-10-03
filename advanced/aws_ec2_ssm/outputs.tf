output "backend_bastion_id" {
  description = "EC2 Instance ID of the backend bastion"
  value       = var.bastions_enabled ? module.backend_bastion[0].instance_id : ""
}

output "frontend_bastion_id" {
  description = "EC2 Instance ID of the frontend bastion"
  value       = var.bastions_enabled ? module.frontend_bastion[0].instance_id : ""
}
