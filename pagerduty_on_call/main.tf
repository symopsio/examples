provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

############ General AWS Secrets Manager Setup ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/sym"
  version = ">= 1.0.0"

  # The aws/secretsmgr addon is required to access secrets
  addons = ["aws/secretsmgr"]

  environment = "main"
}

# An Integration that tells the Sym Runtime resource which AWS Role to assume
# (The AWS Role created by the runtime_connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "main-runtime"

  external_id = module.runtime_connector.settings.account_id
  settings    = module.runtime_connector.settings
}

# This resource tells Sym which role to use to access your AWS Secrets Manager
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "main-sym-secrets"

  settings = {
    context_id = sym_integration.runtime_context.id
  }
}

############ PagerDuty Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your PagerDuty API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/pagerduty-api-key" --secret-string "YOUR-PAGERDUTY-API-KEY"
resource "aws_secretsmanager_secret" "pagerduty_api_key" {
  name        = "main/pagerduty-api-key"
  description = "API Key for Sym to call PagerDuty APIs"

  # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
  # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
  tags = {
    SymEnv = "main"
  }
}

# This resources tells Sym how to access your PagerDuty API Key.
resource "sym_secret" "pagerduty_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.pagerduty_api_key.name
}

# A PagerDuty Integration that can be included in your `sym_environment` to enable `sym.sdk.integrations.pagerduty` methods
resource "sym_integration" "pagerduty" {
  type        = "pagerduty"
  name        = "main-pagerduty-integration"
  external_id = "sym-example.pagerduty.com"

  settings = {
    # `type=pagerduty` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your PagerDuty API Key
    api_token_secret = sym_secret.pagerduty_api_key.id
  }
}

############ Basic Approval Flow ##############

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # prompt_fields_json defines custom form fields for the Slack modal that
    # requesters fill out to make their requests.
    prompt_fields_json = jsonencode([
      {
        name     = "resource"
        label    = "What do you need access to?"
        type     = "string"
        required = true
      },
      {
        name     = "reason"
        label    = "Why do you need access?"
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
    slack_id = sym_integration.slack.id

    # This `pagerduty_id` is required to be able to use the `pagerduty` SDK methods
    # It tells the Sym Runtime to use the API Token defined in the `sym_integration.pagerduty` resource
    pagerduty_id = sym_integration.pagerduty.id
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
