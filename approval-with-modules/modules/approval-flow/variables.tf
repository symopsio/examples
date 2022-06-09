variable "environment_id" {
  description = "The unique ID of the Sym environment this Flow belongs to."
  type        = string
  default     = "main"
}

variable "environment_name" {
  description = "The name of the Sym environment this Flow belongs to."
  type        = string
  default     = "main"
}

variable "flow_variables" {
  description = "Configuration values for the Flow, available in its implementation for hooks and reducers."
  type        = map(string)
  default     = {}
}
