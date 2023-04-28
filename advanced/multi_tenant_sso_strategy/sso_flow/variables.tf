variable "sym_environment" {
  description = "The sym_environment the flow is being deployed to"
  type        = object({ id = string, name = string })
}

variable "sym_runtime_connector_role" {
  description = "The Sym Runtime Connector Role declared in runtime.tf"
  type        = object({ arn = string, name = string })
}

variable "permission_set_name" {
  description = "The name of the SSO Permission Set that will be assigned to users"
  type        = string
}

variable "account_id" {
  description = "The AWS Account ID in the tenant where the Permission Set will be assigned to users."
  type        = string
}

variable "flow_name" {
  description = "A unique slug for this Flow"
  type        = string
}

variable "flow_label" {
  description = "A display name for this Flow"
  type        = string
  default     = ""
}
