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

variable "slack_workspace_id" {
  description = "The Slack Workspace ID to use for your Slack integration."
  type        = string
}
