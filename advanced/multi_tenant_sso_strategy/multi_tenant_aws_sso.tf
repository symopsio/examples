locals {
  customer_connector_roles = [
    for tenant_slug, tenant_settings in var.customer_tenants :
    "arn:aws:iam::${tenant_settings["sso_account_id"]}:role/sym/*"
  ]
}

# A module that creates an AWS SSO Sym Flow that escalates Users as configured by the "customer_tenants` tfvar.
module "sso_access" {
  for_each = var.customer_tenants

  source = "./sso_flow"

  account_id                 = each.value.target_account_id
  permission_set_arn         = each.value.permission_set_arn
  sso_connector_settings     = each.value.sso_connector_settings
  sym_environment            = sym_environment.this
  sym_runtime_connector_role = aws_iam_role.sym_runtime_connector_role
  tenant_slug                = each.key
}

resource "aws_iam_policy" "sso_assume_roles" {
  name = "${local.role_name}_SSOAssumeRoles"
  path = "/sym/"

  description = "This policy allows the Sym Runtime to assume roles in the /sym/ path in the given AWS SSO management accounts."
  policy = jsonencode({
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = local.customer_connector_roles
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "attach_assume_roles_sso" {
  policy_arn = aws_iam_policy.sso_assume_roles.arn
  role       = aws_iam_role.sym_runtime_connector_role.name
}
