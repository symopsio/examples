# In this example, we are terraform a basic lambda function that just prints the event on escalate/de-escalate
# Replace references to `module.lambda_function` with your custom AWS Lambda
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.36.0"

  function_name = "your_lambda"
  description   = "A Lambda to be invoked on escalate and de-escalate"
  handler       = "handler.lambda_handler"
  runtime       = "python3.8"

  source_path = "${path.module}/lambda_src"
}

# The AWS IAM Resources that enable Sym to invoke your Lambda functions.
module "lambda_connector" {
  source  = "symopsio/lambda-connector/aws"
  version = ">= 1.0.0"

  environment       = "main"
  lambda_arns       = [module.lambda_function.lambda_function_arn]

  # The aws_iam_role.sym_runtime_connector_role resource is defined in `runtime.tf`
  runtime_role_arns = [aws_iam_role.sym_runtime_connector_role.arn]
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
resource "sym_target" "super-secret-button" {
  type  = "aws_lambda_function"
  name  = "super-secret-button"
  label = "Super Secret Button"

  settings = {
    # `type=aws_lambda_function` sym_targets have a required setting `arn`
    # which must be the ARN of the AWS Lambda that will be invoked on escalate and de-escalate
    arn = module.lambda_function.lambda_function_arn
  }
}

# The Strategy your Flow uses to manage access
resource "sym_strategy" "lambda" {
  type = "aws_lambda"
  name = "main-lambda-strategy"

  # The integration
  integration_id = sym_integration.lambda_context.id
  targets        = [sym_target.super-secret-button.id]
}

# A Sym Flow that executes an AWS Lambda on escalate and de-escalate
resource "sym_flow" "this" {
  name  = "aws-lambda"
  label = "Super Secret Access"

  implementation = "${path.module}/impl.py"

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.lambda.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }

    prompt_field {
      name           = "duration"
      type           = "duration"
      allowed_values = ["30m", "1h"]
      required       = true
    }
  }
}
