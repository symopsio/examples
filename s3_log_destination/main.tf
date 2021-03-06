provider "sym" {
  org = "sym-example"
}

############ Connecting Sym with your AWS Account with Kinesis Firehose Permissions ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime-connector" {
  source  = "symopsio/runtime-connector/sym"
  version = ">= 1.0.0"

  environment = "main"

  # the aws/kinesis-firehose addon is required to push logs to Kinesis Firehose
  addons = ["aws/kinesis-firehose"]
}

# An Integration that tells the Sym Runtime which IAM Role to assume in your Account
# (The IAM Role created by the runtime-connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "runtime-main"

  settings    = module.runtime-connector.settings
  external_id = module.runtime-connector.settings.account_id
}

############ Creating a Kinesis Firehose Delivery Stream ##############

# The AWS dependencies required to declare a Kinesis Firehose, such as the
# IAM role the Firehose will assume and the backup S3 bucket.
# This is not required, as it is just an abstraction of the dependencies.
# You may declare these resources manually if you wish.
module "kinesis-firehose-connector" {
  source  = "symopsio/kinesis-firehose-connector/sym"
  version = ">= 1.0.0"

  environment = "main"
}

# A Kinesis Firehose Delivery Stream that sends logs to an S3 bucket configured by the kinesis-firehose-connector module
resource "aws_kinesis_firehose_delivery_stream" "sym_logs" {
  name        = "SymS3ReportingLogsMain"
  destination = "extended_s3"

  extended_s3_configuration {
    # The IAM Role and S3 Bucket are declared by the kinesis-firehose-connector module
    role_arn   = module.kinesis-firehose-connector.firehose_role_arn
    bucket_arn = module.kinesis-firehose-connector.firehose_bucket_arn
  }

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime-connector` module
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
