
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
  name = "${local.environment_name}-lambda-strategy"

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
