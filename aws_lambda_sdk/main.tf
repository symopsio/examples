provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

# If you have a lambda already Terraformed, replace the references to module.lambda_function
# with references to your aws_lambda_function resource, and remove this module.
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.36.0"

  function_name = "your_lambda"
  description   = "A Lambda to be called from impl.py"
  handler       = "handler.lambda_handler"
  runtime       = "python3.8"

  source_path = "${path.module}/lambda_src"
}

############ Give Sym Runtime Permissions to Execute your AWS Lambda ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = ">= 1.0.0"

  environment = "main"
}

# An Integration that tells the Sym Runtime resource which AWS Role to assume
# (The AWS Role created by the runtime_connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "runtime-main"

  external_id = module.runtime_connector.settings.account_id
  settings    = module.runtime_connector.settings
}

# The AWS IAM Resources that enable Sym to invoke your Lambda functions.
module "lambda_connector" {
  source  = "symopsio/lambda-connector/aws"
  version = ">= 1.0.0"

  environment       = "main"
  lambda_arns       = [module.lambda_function.lambda_function_arn]
  runtime_role_arns = [module.runtime_connector.settings.role_arn]
}

# The Integration your Strategy uses to invoke Lambdas.
resource "sym_integration" "lambda_context" {
  type = "permission_context"
  name = "lambda-context-main"

  external_id = module.lambda_connector.settings.account_id
  settings    = module.lambda_connector.settings
}

############ Flow with Lambda ARN as a Flow Variable ##############

resource "sym_flow" "this" {
  name  = "aws-lambda-from-sdk"
  label = "AWS Lambda SDK Example"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  vars = {
    # Make your lambda ARN automagically available in your impl.py
    lambda_arn = module.lambda_function.lambda_function_arn
  }

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

    # This `aws_lambda_id` is required to be able to use the `aws_lambda` SDK methods
    aws_lambda_id = sym_integration.lambda_context.id
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

  # Give the Sym Runtime the permissions defined by the runtime_connector module.
  context_id = sym_integration.runtime_context.id
}
