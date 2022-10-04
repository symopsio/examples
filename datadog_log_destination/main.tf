provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

############ Connecting Sym with your AWS Account with Kinesis Firehose Permissions ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = ">= 1.0.0"

  environment = "main"

  # the aws/kinesis-firehose addon is required to push logs to Kinesis Firehose -> Datadog
  addons = ["aws/kinesis-firehose"]
}

# An Integration that tells the Sym Runtime which IAM Role to assume in your Account
# (The IAM Role created by the runtime_connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "runtime-main"

  settings    = module.runtime_connector.settings
  external_id = module.runtime_connector.settings.account_id
}

############ Creating a Kinesis Firehose Delivery Stream to Datadog ##############

# This module creates a AWS Kinesis Firehose Delivery Stream that pipes logs to Datadog
module "datadog_connector" {
  source  = "symopsio/datadog-connector/aws"
  version = ">= 1.0.2"

  environment = "main"

  # This variable should NOT be checked into version control!
  # Set it in an untracked tfvars file (e.g. `secrets.tfvars`)
  # or as an environment variable: `export TF_VAR_datadog_access_key="my-access-key"`
  datadog_access_key = var.datadog_access_key
}

resource "sym_log_destination" "datadog" {
  type = "kinesis_firehose"

  # The Runtime Permission Context has Kinesis Firehose permissions from the aws/kinesis-firehose add-on
  integration_id = sym_integration.runtime_context.id

  settings = {
    # The firehose stream name is outputted by the datadog_connector module
    stream_name = module.datadog_connector.firehose_name
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
  log_destination_ids = [sym_log_destination.datadog.id]

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
