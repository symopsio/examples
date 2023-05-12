############ Runtime Connector Setup ##############
# The runtime_connector module creates an IAM Role that the Sym Runtime can assume to execute operations in your AWS account.
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name
}

############ AWS Lambda Connector Setup ##############
# In this example, we are Terraforming a basic lambda function that just prints the event on escalate/de-escalate
# Replace references to `module.lambda_function` with your custom AWS Lambda, if you have one available.
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

  environment = local.environment_name
  lambda_arns = [module.lambda_function.lambda_function_arn]

  runtime_role_arns = [module.runtime_connector.sym_runtime_connector_role.arn]
}

# The Integration your Strategy uses to invoke Lambdas.
resource "sym_integration" "lambda_context" {
  type = "permission_context"
  name = "${local.environment_name}-lambda-context"

  external_id = module.lambda_connector.settings.account_id
  settings    = module.lambda_connector.settings
}
