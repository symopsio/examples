provider "aws" {
  region = var.aws_region
}

provider "sym" {
  org = var.sym_org_slug
}


resource "sym_flow" "this" {
  name  = "ci-approval"
  label = "CI Approval"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  vars = var.flow_variables

  params = {
    # allowed_sources_json defines the sources from which this flow can be
    # invoked from. Valid values: "api", "slack".
    allowed_sources_json = jsonencode(["api"])

    # prompt_fields_json defines custom form fields for the Slack modal that
    # requesters fill out to make their requests.
    prompt_fields_json = jsonencode([
      {
        name     = "workflow_url"
        label    = "CI Workflow URL"
        type     = "string"
        required = true
      },
      {
        name     = "merging_user"
        label    = "User who merged PR"
        type     = "string"
        required = true
      },
      {
        name     = "workflow_id"
        label    = "CircleCI workflow"
        type     = "string"
        required = true
      }
    ])
  }
}

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = var.environment_name
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id    = sym_integration.slack.id
    circleci_id = sym_integration.circleci.id
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

resource "sym_runtime" "this" {
  name = var.environment_name
}


module "runtime_connector" {
  source  = "terraform.symops.com/symopsio/runtime-connector/sym"
  version = ">= 1.1.0"

  addons      = ["aws/secretsmgr"]
  environment = var.environment_name

  sym_account_ids = var.sym_account_ids
}

# Secrets storage that Sym integrations can refer to
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = var.environment_name

  settings = {
    context_id = sym_integration.runtime_context.id
  }
}


# This will be used by Sym `on_approve` hook to resume the CircleCI workflow.
resource "aws_secretsmanager_secret" "circleci_api_key" {
  name        = "sym/${var.environment_name}/circleci-api-key"
  description = "CircleCI API key for the Sym deploy flow"

  tags = {
    "SymEnv" = var.environment_name
  }
}

resource "sym_secret" "circleci_api_key" {
  path      = aws_secretsmanager_secret.circleci_api_key.name
  source_id = sym_secrets.this.id
}

# The base permissions that a workflow has access to
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "runtime-${var.environment_name}"

  external_id = module.runtime_connector.settings.account_id
  settings    = module.runtime_connector.settings

}

resource "sym_integration" "circleci" {
  type        = "custom"
  name        = "circleci"
  external_id = "symopsio"

  settings = {
    secret_ids_json = jsonencode([sym_secret.circleci_api_key.id])
  }
}
