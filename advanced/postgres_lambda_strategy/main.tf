provider "aws" {
  region = "us-east-1"
}

provider "sym" {
  org = "sym-example"
}

############ Give Sym Runtime Permissions to execute your AWS Lambda ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/sym"
  version = ">= 1.0.0"

  environment = "main"

  tags = var.tags
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
  source  = "symopsio/lambda-connector/sym"
  version = ">= 1.0.0"

  environment       = "main"
  lambda_arns       = [module.postgres_lambda_function.lambda_function_arn]
  runtime_role_arns = [module.runtime_connector.settings.role_arn]

  tags = var.tags
}

# The Integration your Strategy uses to invoke Lambdas.
# It points to to the AWS IAM resources created by the `lambda_connector` module.
# This integration provides your Strategy the permissions needed to invoke your Lambda.
resource "sym_integration" "lambda_context" {
  type = "permission_context"
  name = "lambda-context-main"

  external_id = module.lambda_connector.settings.account_id
  settings    = module.lambda_connector.settings
}

############ Lambda Strategy Setup ##############

# A target AWS Lambda that will be invoked on escalate and de-escalate.
# The `name` will be used in the lambda to decide which resource to manage access to
resource "sym_target" "postgres_roles" {
  for_each = { for target in var.postgres_roles : target["name"] => target["label"] }

  type  = "aws_lambda_function"
  name  = each.key
  label = each.value

  settings = {
    # `type=aws_lambda_function` sym_targets have a required setting `arn`
    # which must be the ARN of the AWS Lambda that will be invoked on escalate and de-escalate
    arn = module.postgres_lambda_function.lambda_function_arn
  }
}

# The Strategy your Flow uses to manage access
resource "sym_strategy" "lambda" {
  type = "aws_lambda"
  name = "main-lambda-strategy"

  # The integration containing the permission context necessary to invoke your lambda
  integration_id = sym_integration.lambda_context.id
  targets        = [for target in sym_target.postgres_roles : target.id]
}

# A Sym Flow that executes an AWS Lambda on escalate and de-escalate
resource "sym_flow" "this" {
  name  = "postgres"
  label = "Postgres Access"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.lambda.id

    # prompt_fields_json defines custom form fields for the Slack modal that
    # requesters fill out to make their requests.
    prompt_fields_json = jsonencode([
      {
        name     = "reason"
        label    = "Why do you need access?"
        type     = "string"
        required = true
      },
      {
        name           = "duration"
        type           = "duration"
        allowed_values = ["30m", "1h"]
        required       = true
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
