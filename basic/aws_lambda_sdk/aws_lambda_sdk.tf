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

  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  vars = {
    # Make your lambda ARN automagically available in your impl.py
    lambda_arn = module.lambda_function.lambda_function_arn
  }

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
