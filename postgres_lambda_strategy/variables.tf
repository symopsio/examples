variable "db_config" {
  description = "Connection configuration for your Postgres Database"
  type        = object({ host = string, port = number, user = string, pass = string })
}

variable "security_group_id" {
  description = "Security group for the lambda"
  type        = string
}

variable "subnet_ids" {
  description = "VPC subnet ids for the function"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
