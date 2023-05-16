# The AWS dependencies required to declare a Kinesis Firehose, such as the
# IAM role the Firehose will assume and the backup S3 bucket.
# This is not required, as it is just an abstraction of the dependencies.
# You may declare these resources manually if you wish.
module "kinesis_firehose_connector" {
  source  = "symopsio/kinesis-firehose-connector/aws"
  version = "~> 3.0"

  environment = local.environment_name
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
    # This SymEnv tag is required and MUST match the `environment` variable
    # passed into the `kinesis_firehose_access` module in the `connectors.tf` file
    SymEnv = local.environment_name
  }
}

# A Kinesis Firehose Log destination pointing to the S3 Firehose Delivery Stream
resource "sym_log_destination" "s3_firehose" {
  type           = "kinesis_firehose"
  integration_id = module.runtime_connector.sym_integration.id

  settings = {
    stream_name = aws_kinesis_firehose_delivery_stream.sym_logs.name
  }
}

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
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
