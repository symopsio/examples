variable "db_config" {
  description = "Connection configuration for your Postgres Database, required if db_enabled is false"
  type        = object({ host = string, port = number, user = string, pass = string })
  default     = null
}

variable "db_enabled" {
  description = "Whether or not to create a database to use with the integration"
  type        = bool
  default     = false
}

variable "security_group_id" {
  description = "Lambda security group, required if db_enabled is false"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "VPC subnet ids, required if db_enabled is false"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = { "Vendor" = "symops.com" }
}
