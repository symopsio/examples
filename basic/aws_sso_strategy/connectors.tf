locals {
  aws_region = "us-east-1"
}

provider "aws" {
  region = local.aws_region
}

############ Runtime Connector Setup ##############
# The runtime_connector module creates an IAM Role that the Sym Runtime can assume to execute operations in your AWS account.
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name

  # Allow the Runtime Connector Role to assume IAM Roles in the SSO Account as well.
  account_id_safelist = [data.aws_caller_identity.sso.account_id]
}

############ AWS SSO Connector Setup ##############
# Set up a different provider for the SSO connector.
# This is because you typically will put your Sym resources in a different
# AWS account from your AWS SSO instance.
provider "aws" {
  alias  = "sso"
  region = "us-east-1"

  # Change this profile name to a valid AWS profile for the AWS account where
  # your AWS SSO instance lives.
  profile = "sso"
}

# Get the AWS Account ID for the SSO profile.
data "aws_caller_identity" "sso" {
  provider = aws.sso
}

# The AWS IAM Resources that enable Sym to manage SSO Permission Sets
module "sso_connector" {
  source  = "symopsio/sso-connector/aws"
  version = "~> 2.0"

  # Provision the SSO connector in the AWS account where your AWS
  # SSO instance lives.
  providers = {
    aws = aws.sso
  }

  environment = local.environment_name
  runtime_role_arns = [module.runtime_connector.sym_runtime_connector_role.arn]
}

# The Integration your Strategy uses to manage SSO Permission Sets
resource "sym_integration" "sso_context" {
  type        = "permission_context"
  name        = "${local.environment_name}-sso"
  external_id = module.sso_connector.settings["instance_arn"]
  settings    = module.sso_connector.settings
}
