variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "db_instance_type" {
  description = "Type of the DB instance"
  type        = string
  default     = "db.t3.medium"
}

variable "namespace" {
  description = "Namespace qualifier"
  type        = string
  default     = "sym"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
