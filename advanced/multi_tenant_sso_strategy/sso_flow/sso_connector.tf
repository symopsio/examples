############ AWS SSO Connector Setup ##############
# Set up a different AWS provider for the SSO connector.
# This is necessary in the typical setup where Sym resources are provisioned in
# a different AWS account than the AWS IAM Identity Center (SSO) instance.
# If you do not do so yet, we recommend using a delegated administration account to manage your SSO instance,
# as described here: https://docs.aws.amazon.com/singlesignon/latest/userguide/delegated-admin.html

# Get the AWS Account ID for the SSO profile.
data "aws_caller_identity" "sso" {}

# The AWS IAM Resources that enable Sym to manage SSO Permission Sets and Groups
module "sso_connector" {
  source  = "symopsio/sso-connector/aws"
  version = ">= 1.0.0"

  environment       = var.sym_environment.name
  runtime_role_arns = [var.sym_runtime_connector_role.arn]
}


# The Integration the Sym Strategy uses to manage SSO Permission Sets and Groups
resource "sym_integration" "aws_sso_context" {
  type        = "permission_context"
  name        = "${var.sym_environment.name}-aws-sso-context"
  external_id = module.sso_connector.settings["instance_arn"]
  settings    = module.sso_connector.settings
}
