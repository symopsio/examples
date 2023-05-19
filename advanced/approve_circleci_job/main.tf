provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  environment_name = "main"
}

############ General AWS Secrets Manager Setup ##############

# The runtime_connector module creates an IAM Role that the Sym Runtime can assume to execute operations in your AWS account.
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name
}

# This secrets_manager_access module defines an AWS IAM Policy and attachment that grants the Sym Runtime Role
# the permissions to read secrets from AWS Secrets Manager that are under the /sym/ path and tagged with
# `SymEnv = local.environment`.
module "secrets_manager_access" {
  source  = "symopsio/secretsmgr-addon/aws"
  version = "~> 1.1"

  environment   = local.environment_name
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}

# This resource tells Sym how to access your AWS account's Secrets Manager instance.
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "${local.environment_name}-sym-secrets"

  settings = {
    # This tells Sym to use the sym_integration defined in the runtime_connector module when accessing
    # your AWS account's Secrets Manager.
    context_id = module.runtime_connector.sym_integration.id
  }
}

############ CircleCI Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your Okta API Key.
# This will be used by Sym `on_approve` hook to resume the CircleCI workflow.
# Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/${local.environment_name}/circleci-api-key" --secret-string "YOUR-CIRCLECI-API-KEY"

resource "aws_secretsmanager_secret" "circleci_api_key" {
  name        = "sym/${local.environment_name}/circleci-api-key"
  description = "CircleCI API key for the Sym deploy flow"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    "SymEnv" = local.environment_name
  }
}

# This resource tells Sym how to access your CIRCLECI API Key.
resource "sym_secret" "circleci_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  path = aws_secretsmanager_secret.circleci_api_key.name

  # Name of the key in AWS Secrets Manager
  source_id = sym_secrets.this.id
}

# A Custom Integration that can be included in your `sym_environment` so your CircleCI Secret is available in hooks
resource "sym_integration" "circleci" {
  type = "custom"
  name = "circleci"

  # A unique ID for this integration
  external_id = "symopsio"

  settings = {
    secret_ids_json = jsonencode([sym_secret.circleci_api_key.id])
  }
}

############ API-triggered Approval Flow for CircleCI ##############

resource "sym_flow" "this" {
  name  = "ci-approval"
  label = "CI Approval"

  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params {
    # allowed_sources defines the sources from which this flow can be invoked.
    # Valid values: "api", "slack"
    allowed_sources = ["api"]

    # Each prompt_field defines a key for `flow_inputs` to be passed in the API request body
    prompt_field {
      name     = "workflow_url"
      label    = "CI Workflow URL"
      type     = "string"
      required = true
    }

    prompt_field {
      name     = "merging_user"
      label    = "User who merged PR"
      type     = "string"
      required = true
    }

    prompt_field {
      name     = "workflow_id"
      label    = "CircleCI workflow"
      type     = "string"
      required = true
    }
  }
}

############ Basic Environment Setup ##############

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = local.environment_name
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id    = sym_integration.slack.id
    circleci_id = sym_integration.circleci.id
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
