locals {
  aws_region = "us-east-1"
}

provider "aws" {
  region = local.aws_region
}

# The runtime_connector module creates an IAM Role that the Sym Runtime can assume to execute operations in your AWS account.
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name
}

# The kinesis_firehose_access module generates an AWS IAM Policy that grants permissions to publish to the given AWS Kinesis Firehose.
# Those permissions will be granted to the Runtime Connector IAM Role so that the Sym Runtime can publish to the Kinesis Firehose.
module "kinesis_firehose_access" {
  source  = "symopsio/kinesis-firehose-addon/aws"
  version = ">= 1.1.0"

  environment = local.environment_name
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}
