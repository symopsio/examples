############ Sym's Postgres Lambda Integration ##############

data "aws_caller_identity" "current" {}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  function_name   = "sym-postgres"
  db_password_key = "/symops.com/${local.function_name}/PG_PASSWORD"

  security_group_id = var.db_enabled ? module.db[0].security_group_id : var.security_group_id
  subnet_ids        = var.db_enabled ? module.db[0].private_subnet_ids : var.subnet_ids
  db_config         = var.db_enabled ? module.db[0].db_config : var.db_config
}

# Optionally set up a database to use for testing the integration
module "db" {
  source = "./postgres_db"
  count  = var.db_enabled ? 1 : 0

  tags = var.tags
}

# Set up the Sym Postgres Lambda Function
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.36.0"

  function_name = local.function_name
  description   = "Sym Postgres Integration"
  handler       = "handler.handle"
  runtime       = "python3.8"

  source_path = [{
    path = "${path.module}/lambda_src/handler",
    # Don't do a pip install here since the layer handles this, just
    # package the handler implementation itself.
    pip_requirements = false,
    patterns = [
      "!__pycache__/.*",
    ]
  }]

  layers = [
    module.lambda_layer.lambda_layer_arn,
  ]

  attach_policy_json = true
  policy_json = jsonencode({
    Statement = [{
      Action = [
        "ssm:GetParameter*"
      ],
      Effect = "Allow"
      Resource = [
        "arn:aws:ssm:*:${local.account_id}:parameter/symops.com/${local.function_name}/*"
      ]
    }]
    Version = "2012-10-17"
  })

  timeout = 10

  environment_variables = {
    "PG_HOST"         = local.db_config["host"]
    "PG_PASSWORD_KEY" = local.db_password_key
    "PG_PORT"         = local.db_config["port"]
    "PG_USER"         = local.db_config["user"]
  }

  vpc_subnet_ids         = local.subnet_ids
  vpc_security_group_ids = [local.security_group_id]
  attach_network_policy  = true

  tags = var.tags
}

# We must use a layer in order to install the correct native pscopg2 library
# for the lambda runtime
module "lambda_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.36.0"

  create_layer = true

  layer_name          = "sym-postgres-layer"
  description         = "Sym Postgres Dependencies"
  compatible_runtimes = ["python3.8"]

  source_path = [{
    path             = "${path.module}/lambda_src/handler",
    pip_requirements = true,
    prefix_in_zip    = "python",
    patterns = [
      "!python/__pycache__/.*",
      # Exclude files in the top-level directory
      "!python/[^/]+"
    ]
  }]

  build_in_docker = true
  runtime         = "python3.8"

  tags = var.tags
}

# SSM parameter to store the Postgres password in.
# Ensure your state is encrypted if you configure a production password here,
# or ignore lifecycle changes and configure the password using a different
# process.
resource "aws_ssm_parameter" "db_password" {
  name  = local.db_password_key
  type  = "SecureString"
  value = local.db_config["pass"]

  tags = var.tags
}
