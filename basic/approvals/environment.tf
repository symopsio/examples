provider "sym" {
  org = var.sym_org_id
}

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = var.environment_name
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "${var.environment_name}-slack"

  external_id = var.slack_workspace_id
}

# This sym_error_logger will output any warnings and errors that occur during
# execution of a sym_flow to a specified channel in Slack.
resource "sym_error_logger" "slack" {
  integration_id = sym_integration.slack.id
  destination    = var.error_channel_name
}
