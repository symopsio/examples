############ Sym's PostgreSQL Lambda Integration ##############
locals {
  account_id      = data.aws_caller_identity.current.account_id
  function_name   = "sym-postgres"
  db_password_key = "/symops.com/${local.function_name}/PG_PASSWORD"

  security_group_ids = var.db_enabled ? [module.db[0].security_group_id] : var.security_group_ids
  subnet_ids         = var.db_enabled ? module.db[0].private_subnet_ids : var.subnet_ids
  db_config          = var.db_enabled ? module.db[0].db_config : var.db_config
}

# Set up the Sym PostgreSQL Lambda Function
module "postgres_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.6.0"

  function_name = local.function_name
  description   = "Sym PostgreSQL Integration"
  handler       = "handler.handle"
  runtime       = "python3.8"

  source_path = [{
    path = "${path.module}/lambda_src",
    # Don't do a pip install here since the layer handles this, just
    # package the handler implementation itself.
    pip_requirements = false,
    patterns = [
      "!__pycache__/.*",
      "!test/.*"
    ]
  }]

  layers = [
    module.postgres_lambda_layer.lambda_layer_arn,
  ]

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_policy.json

  timeout = 10

  environment_variables = {
    "PG_HOST"         = local.db_config["host"]
    "PG_PASSWORD_KEY" = local.db_password_key
    "PG_PORT"         = local.db_config["port"]
    "PG_USER"         = local.db_config["user"]
  }

  vpc_subnet_ids         = local.subnet_ids
  vpc_security_group_ids = local.security_group_ids
  attach_network_policy  = true

  tags = var.tags
}

# Give the lambda permissions to read the database password.
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter*"]
    resources = [
      "arn:aws:ssm:*:${local.account_id}:parameter/symops.com/${local.function_name}/*"
    ]
  }
}

# We must use a layer in order to install the correct native pscopg2 library
# for the lambda runtime
module "postgres_lambda_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0.2"

  create_layer = true

  layer_name          = "${local.function_name}-layer"
  description         = "Sym PostgreSQL Dependencies"
  compatible_runtimes = ["python3.8"]

  source_path = [{
    path             = "${path.module}/lambda_src/requirements.txt",
    pip_requirements = true,
    prefix_in_zip    = "python",
  }]

  build_in_docker = true
  runtime         = "python3.8"

  tags = var.tags
}

# SSM parameter to store the PostgreSQL password in.
#
# Ensure your Terraform state is encrypted if you supplied a production
# password in your db_config.
#
# You can also configure a temporary password and uncomment the block
# below to ignore lifecycle changes. Then you can manage the password outside of
# the Terraform provisioning lifecycle, and outside of Terraform state.
resource "aws_ssm_parameter" "postgres_password" {
  name  = local.db_password_key
  type  = "SecureString"
  value = local.db_config["pass"]

  tags = var.tags

  /*
   * Uncomment this to manage the password outside of Terraform state
  lifecycle {
    ignore_changes = [value, version]
  }
  */
}
