############ Runtime Connector Setup ##############
# The runtime_connector module creates an IAM Role that the Sym Runtime can assume to execute operations in your AWS account.
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name
}

############ AWS IAM Connector Setup ##############
# The AWS IAM Resources that enable Sym to manage IAM Groups
module "iam_connector" {
  source  = "symopsio/iam-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name

  # The aws_iam_role.sym_runtime_connector_role resource is defined in `runtime.tf`
  runtime_role_arns = [module.runtime_connector.sym_runtime_connector_role.arn]
}

# The Integration your Strategy uses to manage IAM Groups
resource "sym_integration" "iam_context" {
  type        = "permission_context"
  name        = "${local.environment_name}-iam"
  external_id = module.iam_connector.settings.account_id
  settings    = module.iam_connector.settings
}
