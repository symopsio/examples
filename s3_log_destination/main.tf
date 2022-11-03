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

  # the aws/kinesis-firehose addon is required to push logs to Kinesis Firehose
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

############ Creating a Kinesis Firehose Delivery Stream ##############

# The AWS dependencies required to declare a Kinesis Firehose, such as the
# IAM role the Firehose will assume and the backup S3 bucket.
# This is not required, as it is just an abstraction of the dependencies.
# You may declare these resources manually if you wish.
module "kinesis_firehose_connector" {
  source  = "symopsio/kinesis-firehose-connector/aws"
  version = ">= 3.0.0"

  environment = "main"
}

# A Kinesis Firehose Delivery Stream that sends logs to an S3 bucket configured by the kinesis_firehose_connector module
resource "aws_kinesis_firehose_delivery_stream" "sym_logs" {
  name        = "SymS3ReportingLogsMain"
  destination = "extended_s3"

  extended_s3_configuration {
    # The IAM Role and S3 Bucket are declared by the kinesis_firehose_connector module
    role_arn   = module.kinesis_firehose_connector.firehose_role_arn
    bucket_arn = module.kinesis_firehose_connector.firehose_bucket_arn
  }

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/kinesis-firehose add-on only grants access to Firehoses tagged with a matching SymEnv value
    SymEnv = "main"
  }
}

# A Kinesis Firehose Log destination pointing to the S3 Firehose Delivery Stream
resource "sym_log_destination" "s3_firehose" {
  type           = "kinesis_firehose"
  integration_id = sym_integration.runtime_context.id
  settings = {
    stream_name = aws_kinesis_firehose_delivery_stream.sym_logs.name
  }
}

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
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  # All requests in this environment will be logged and sent to these log destinations
  log_destination_ids = [sym_log_destination.s3_firehose.id]

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
