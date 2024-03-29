locals {
  environment_name = "main"
}

provider "sym" {
  org = "sym-example"
}

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = local.environment_name
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id

    # The GitHub Access Token is implicitly available to your GitHub Flow's impl.py,
    # so this line is optional if you only need to use `sym.sdk.integrations.github` methods in your GitHub Flow.
    #
    # But if you wish to use the `sym.sdk.integrations.github` methods in a different Flow in this Environment,
    # you must include this `github_id = sym_integration.github.id` here.
    github_id = sym_integration.github.id
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
