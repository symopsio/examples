variable "directory_group_name" {
  description = "Existing AWS Directory Group Name, used for Permission Set Provisioning"
  type        = string
  /*
   * The AWSSecurityAuditors group is one of the default groups created by AWS
   * Control Tower.
   */
  default = "AWSSecurityAuditors"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = { "Vendor" = "symops.com" }
}
