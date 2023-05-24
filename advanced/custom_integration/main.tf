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

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
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

############ Custom Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your VictorOps API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/${local.environment_name}/victorops-api-key" --secret-string "YOUR-VICTOROPS-API-KEY"
resource "aws_secretsmanager_secret" "victorops_api_key" {
  name        = "sym/${local.environment_name}/victorops-api-key"
  description = "API Key for Sym to call VictorOps APIs"

  # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
  # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
  tags = {
    SymEnv = local.environment_name
  }
}

# This resources tells Sym how to access your VictorOps API Key.
resource "sym_secret" "victorops_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.victorops_api_key.name
}

# A custom integration for VictorOps. Custom integrations let us use secrets in
# the SDK and configure user mappings when necessary
resource "sym_integration" "victorops" {
  type        = "custom"
  name        = "${local.environment_name}-victorops-integration"
  external_id = "9sr1wzgcxfo580c1pna4a55to" # VictorOps API ID

  settings = {
    # `type=custom` sym_integrations use a secret_ids_json property
    secret_ids_json = jsonencode([sym_secret.victorops_api_key.id])
  }
}

############ Basic Approval Flow ##############

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = file("${path.module}/impl.py")
  environment_id = sym_environment.this.id

  params {
    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "resource"
      label    = "What do you need access to?"
      type     = "string"
      required = true
    }

    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
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
    slack_id = sym_integration.slack.id

    # This lets us access the custom API key from within the SDK
    victorops_id = sym_integration.victorops.id
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
