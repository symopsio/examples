provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

############ General AWS Secrets Manager Setup ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime-connector" {
  source  = "symopsio/runtime-connector/sym"
  version = ">= 1.0.0"

  # The aws/secretsmgr addon is required to access secrets
  addons = ["aws/secretsmgr"]

  environment = "main"
}

# An Integration that tells the Sym Runtime resource which AWS Role to assume
# (The AWS Role created by the runtime-connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "runtime-main"

  external_id = module.runtime-connector.settings.account_id
  settings    = module.runtime-connector.settings

}


# This resource tells Sym which role to use to access your AWS Secrets Manager
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "main"

  settings = {
    context_id = sym_integration.runtime_context.id
  }
}

############ CircleCI Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your Okta API Key.
# This will be used by Sym `on_approve` hook to resume the CircleCI workflow.
# Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/main/circleci-api-key" --secret-string "YOUR-CIRCLECI-API-KEY"

resource "aws_secretsmanager_secret" "circleci_api_key" {
  name        = "sym/main/circleci-api-key"
  description = "CircleCI API key for the Sym deploy flow"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime-connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    "SymEnv" = "main"
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

  template = "sym:template:approval:1.0.0"

  implementation = "${path.module}/impl.py"
  #implementation = "${path.module}/impl_with_context.py"

  environment_id = sym_environment.this.id

  params = {
    # allowed_sources_json defines the sources from which this flow can be
    # invoked from. Valid values: "api", "slack".
    allowed_sources_json = jsonencode(["api"])

    # prompt_fields_json defines the `flow_inputs` to be passed in the API request body
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

############ Basic Environment Setup ##############

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = "main"
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id    = sym_integration.slack.id
    circleci_id = sym_integration.circleci.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

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
}
