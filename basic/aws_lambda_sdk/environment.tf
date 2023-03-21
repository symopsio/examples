locals {
  environment_name = "prod"
}

provider "sym" {
  org = "sym-example"
}

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = local.environment_name
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id

    # This `aws_lambda_id` is required to be able to use the `aws_lambda` SDK methods
    aws_lambda_id = sym_integration.lambda_context.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "${local.environment_name}-slack"

  # The external_id for slack integrations is the Slack Workspace ID
  external_id = "T123ABC"
}

# This sym_error_logger will output any warnings and errors that occur during
# execution of a sym_flow to a specified channel in Slack.
resource "sym_error_logger" "slack" {
  integration_id = sym_integration.slack.id
  destination    = "#sym-errors"
}

resource "sym_runtime" "this" {
  name = "main"

  # Give the Sym Runtime the permissions defined by the runtime_connector module.
  context_id = sym_integration.runtime_context.id
}
