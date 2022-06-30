variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

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

variable "sym_account_ids" {
  description = "List of account ids that can assume the Sym runtime role. By default, only Sym production accounts can assume the runtime role."
  type        = list(string)
  default     = ["803477428605"]
}

variable "sym_org_slug" {
  description = "Uniquely identifying slug for your organization in Sym."
  type        = string
}
