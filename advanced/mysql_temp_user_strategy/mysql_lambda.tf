############ Sym's MySQL Lambda Integration ##############
locals {
  account_id      = data.aws_caller_identity.current.account_id
  function_name   = "sym-mysql"
  db_password_key = "/symops.com/${local.function_name}/DB_PASSWORD"

  security_group_ids = var.db_enabled ? [module.db[0].security_group_id] : var.security_group_ids
  subnet_ids         = var.db_enabled ? module.db[0].private_subnet_ids : var.subnet_ids
  db_config          = var.db_enabled ? module.db[0].db_config : var.db_config
}

# Set up the Sym MySQL Lambda Function
module "mysql_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.6.0"

  function_name = local.function_name
  description   = "Sym MySQL Integration"
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
    module.mysql_lambda_layer.lambda_layer_arn,
  ]

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_policy.json

  timeout = 10

  environment_variables = {
    "DB_HOST"         = local.db_config["host"]
    "DB_PASSWORD_KEY" = local.db_password_key
    "DB_PORT"         = local.db_config["port"]
    "DB_USER"         = local.db_config["user"]
  }

  vpc_subnet_ids         = local.subnet_ids
  vpc_security_group_ids = local.security_group_ids
  attach_network_policy  = true

  tags = var.tags
}

# Give the lambda permissions to read the database password
# as well as to create and delete secrets manager secrets, since
# this is where we will store the temporary user credentials.
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter*"]
    resources = [
      "arn:aws:ssm:*:${local.account_id}:parameter/symops.com/${local.function_name}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "secretsmanager:Name"
      values   = ["/symops.com/${local.function_name}/*"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DeleteSecret",
      "secretsmanager:TagResource"
    ]
    resources = [
      "arn:aws:secretsmanager:*:${local.account_id}:secret:/symops.com/${local.function_name}/*"
    ]
  }
}

# Use a layer to store module dependencies
module "mysql_lambda_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0.2"

  create_layer = true

  layer_name          = "${local.function_name}-layer"
  description         = "Sym MySQL Dependencies"
  compatible_runtimes = ["python3.8"]

  source_path = [{
    path             = "${path.module}/lambda_src/requirements.txt",
    pip_requirements = true,
    prefix_in_zip    = "python"
  }]

  build_in_docker = true
  runtime         = "python3.8"

  tags = var.tags
}

# SSM parameter to store the MySQL password in.
#
# Ensure your Terraform state is encrypted if you supplied a production
# password in your db_config.
#
# You can also configure a temporary password and uncomment the block
# below to ignore lifecycle changes. Then you can manage the password outside of
# the Terraform provisioning lifecycle, and outside of Terraform state.
resource "aws_ssm_parameter" "mysql_password" {
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
