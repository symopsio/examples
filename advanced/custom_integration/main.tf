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
  source  = "symopsio/runtime-connector/aws"
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

############ Custom Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your VictorOps API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/victorops-api-key" --secret-string "YOUR-VICTOROPS-API-KEY"
resource "aws_secretsmanager_secret" "victorops_api_key" {
  name        = "main/victorops-api-key"
  description = "API Key for Sym to call VictorOps APIs"

  # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
  # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
  tags = {
    SymEnv = "main"
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
  name        = "main-victorops-integration"
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

  implementation = "${path.module}/impl.py"
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
  name            = "main"
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id

    # This lets us access the custom API key from within the SDK
    victorops_id = sym_integration.victorops.id
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
