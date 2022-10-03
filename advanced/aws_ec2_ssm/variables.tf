variable "bastions_enabled" {
  description = "Enable test instances for trying out Session Manager connections"
  type        = bool
  default     = false
}

variable "private_subnet_id" {
  description = "Private VPC subnet id for the test instances. Required if test instances are enabled"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = { "Vendor" = "symops.com" }
}
