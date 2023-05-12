############ Flow with Lambda ARN as a Flow Variable ##############

resource "sym_flow" "this" {
  name  = "aws-lambda-from-sdk"
  label = "AWS Lambda SDK Example"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
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
