module "secrets_manager_access" {
  source  = "symopsio/secretsmgr-addon/aws"
  version = "~> 1.1"

  environment   = local.environment_name
  iam_role_name = module.runtime_connector.sym_runtime_connector_role.name
}

# This resource tells Sym how to access your AWS account's Secrets Manager instance.
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "${local.environment_name}-sym-secrets"

  settings = {
    # This tells Sym to use the sym_integration defined in the runtime_connector module when accessing
    # your AWS account's Secrets Manager.
    context_id = module.runtime_connector.sym_integration.id
  }
}
