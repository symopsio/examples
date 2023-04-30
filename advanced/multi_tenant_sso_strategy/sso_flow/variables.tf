variable "sym_environment" {
  description = "The sym_environment the flow is being deployed to"
  type        = object({ id = string, name = string })
}

variable "sym_runtime_connector_role" {
  description = "The Sym Runtime Connector Role declared in runtime.tf"
  type        = object({ arn = string, name = string })
}

variable "sso_connector_settings" {
  description = "The output of symopsio/sso-connector/aws after it has been applied to the customer account"
  type = object({
    cloud        = string,
    instance_arn = string,
    region       = string,
    role_arn     = string
  })
}

variable "tenant_slug" {
  description = "A unique slug for the customer whose SSO instance will be escalated to"
  type        = string
}

variable "permission_set_arn" {
  description = "The ARN of the SSO Permission Set that will be assigned to users"
  type        = string
}

variable "account_id" {
  description = "The AWS Account ID in the tenant where the Permission Set will be assigned to users."
  type        = string
}
