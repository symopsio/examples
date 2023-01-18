variable "environment_name" {
  description = "The name of the Sym environment these resources belong to."
  type        = string
  default     = "main"
}

variable "error_channel_name" {
  description = "The name of the Slack channel where Sym errors will be surfaced."
  type        = string
  default     = "#sym-errors"
}

variable "flow_variables" {
  description = "Configuration values for the Flow, available in its implementation for hooks and reducers."
  type        = map(string)
  default     = {}
}

variable "slack_workspace_id" {
  description = "The Slack Workspace ID to use for your Slack integration."
  type        = string
}

variable "sym_org_id" {
  description = "ID for your organization in Sym. (e.g. `S-VJ2IYOCQ74`)"
  type        = string
}

