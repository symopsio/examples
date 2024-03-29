# An example SSO connector module that will be applied to the customer's AWS SSO Instance.
# This will be applied according to the customer's own rules and governance, and the output will be copied and pasted
# into `multi_tenant_aws_sso.tf` to set up the relevant Sym resources to escalate to the customer's SSO instance.

# This should be applied using AWS credentials that have the permissions to read and write IAM Roles in the

provider "aws" {
  region = "us-east-1"

  # This profile should be configured permissions to read and write IAM Roles in the Tenant A SSO Management Account,
  # and permissions to read SSO resources.
  profile = "tenant-foo-sso-provisioning"
}

# SSO management account, as well as read AWS SSO resources.
module "sso_connector" {
  # The AWS IAM Resources that enable Sym to manage SSO Permission Sets and Groups

  source  = "symopsio/sso-connector/aws"
  version = ">= 1.0.0"

  environment = "tenant-foo"

  # This should be the value of aws_iam_role.sym_runtime_connector_role.arn (defined in runtime.tf)
  runtime_role_arns = ["arn:aws:iam::803477428605:role/sym/SymRuntimeSSOExample"]
}

# Output values:
# cloud         = "aws"
# instance_arn  = The SSO Instance ARN
# region        = The SSO region
# role_arn      = The SSO Connector Role ARN
