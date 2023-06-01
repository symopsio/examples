locals {
  aws_region = "us-east-1"

  customer_connector_roles = [
    for tenant_slug, tenant_settings in var.customer_tenants : tenant_settings["sso_account_id"]
  ]
}

provider "aws" {
  region = local.aws_region
}

module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment = local.environment_name

  # Allow the Runtime Connector Role to assume IAM Roles in each customer SSO Account as well.
  account_id_safelist = local.customer_connector_roles
}


# A module that creates an AWS SSO Sym Flow that escalates Users as configured by the "customer_tenants` tfvar.
module "sso_access" {
  for_each = var.customer_tenants

  source = "./sso_flow"

  account_id                 = each.value.target_account_id
  permission_set_arn         = each.value.permission_set_arn
  sso_connector_settings     = each.value.sso_connector_settings
  sym_environment            = sym_environment.this
  sym_runtime_connector_role = module.runtime_connector.sym_runtime_connector_role
  tenant_slug                = each.key
}
