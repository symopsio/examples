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

############ Segment Integration and Secret Setup ##############

# aws secretsmanager put-secret-value --secret-id "main/segment-write-key" --secret-string "YOUR-SEGMENT-WRITE-KEY"
resource "aws_secretsmanager_secret" "segment_write_key" {
  name        = "main/segment-write-key"
  description = "Segment Write Key for Sym Audit Logs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
  }
}

resource "sym_secret" "segment_write_key" {
  # `sym_secrets` is defined in "Manage Secrets with AWS Secrets Manager"
  source_id = sym_secrets.this.id
  path      = aws_secretsmanager_secret.segment_write_key.name
}

resource "sym_integration" "segment" {
  type = "segment"
  name = "main-segment-integration"

  # Your Segment Workspace name
  external_id = "sym-test"

  settings = {
    # This secret was defined in the previous step
    write_key_secret = sym_secret.segment_write_key.id
  }
}

############ Log Destination Setup ##############

resource "sym_log_destination" "segment" {
  type           = "segment"
  integration_id = sym_integration.segment.id

  settings = {
    # A unique name for this log destination
    stream_name = "segment-main"
  }
}

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

  # All requests in this environment will be logged and sent to these log destinations
  log_destination_ids = [sym_log_destination.segment.id]

  integrations = {
    slack_id = sym_integration.slack.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

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
