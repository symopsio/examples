# To apply the modules in this file, you must have valid, active credentials for both AWS profiles.
# For example `aws sso login tenant-a-sso-provisioning && aws sso login tenant-b-sso-provisioning`.
# The $AWS_PROFILE environment variable should be set to the AWS Profile that has credentials to the AWS Account
# in which you wish to deploy your other resources (i.e. the resources defined in runtime.tf).

provider "aws" {
  alias  = "tenant_a"
  region = "us-east-1"

  # This profile should be configured permissions to read and write IAM Roles in the Tenant A SSO Management Account,
  # and permissions to read SSO resources.
  profile = "tenant-a-sso-provisioning"
}

data "aws_caller_identity" "tenant_a" {
  provider = aws.tenant_a
}

# A module that creates an AWS SSO Sym Flow that escalates Users to the 123456789 Account with PowerUser permissions
# in the Tenant A SSO instance.
module "tenant_a_power_user" {
  source = "./sso_flow"

  providers = {
    aws = aws.tenant_a
  }

  account_id                 = "1234567890"
  permission_set_name        = "PowerUser"
  flow_name                  = "tenant-a-power-user"
  flow_label                 = "Tenant A Access"
  sym_environment            = sym_environment.this
  sym_runtime_connector_role = aws_iam_role.sym_runtime_connector_role
}

provider "aws" {
  alias  = "tenant_b"
  region = "us-east-1"

  # This profile should be configured permissions to read and write IAM Roles in the Tenant B SSO Management Account,
  # and permissions to read SSO resources.
  profile = "tenant-b-sso-provisioning"
}

data "aws_caller_identity" "tenant_b" {
  provider = aws.tenant_b
}

# A module that creates an AWS SSO Sym Flow that escalates Users to the 0987654321 Account with PowerUser permissions
# in the Tenant B SSO instance.
module "tenant_b_power_user" {
  source = "./sso_flow"

  providers = {
    aws = aws.tenant_b
  }

  account_id                 = "0987654321"
  permission_set_name        = "PowerUser"
  flow_name                  = "tenant-b-power-user"
  flow_label                 = "Tenant B Access"
  sso_profile_name           = "tenant-b-sso-provisioning"  # This AWS Profile points to the SSO Instance in Tenant B
  sym_environment            = sym_environment.this
  sym_runtime_connector_role = aws_iam_role.sym_runtime_connector_role
}

resource "aws_iam_policy" "sso_assume_roles" {
  name = "${local.role_name}_SSOAssumeRoles"
  path = "/sym/"

  description = "This policy allows the Sym Runtime to assume roles in the /sym/ path in the given AWS SSO accounts."
  policy = jsonencode({
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.tenant_a.account_id}:role/sym/*",
        "arn:aws:iam::${data.aws_caller_identity.tenant_b.account_id}:role/sym/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "attach_assume_roles_sso" {
  policy_arn = aws_iam_policy.sso_assume_roles.arn
  role       = aws_iam_role.sym_runtime_connector_role.name
}
