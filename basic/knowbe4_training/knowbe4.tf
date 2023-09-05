# An AWS Secrets Manager Secret to hold your KnowBe4 API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "$sym/{local.environment_name}/knowbe4-api-key" --secret-string "YOUR-KNOWBE4-API-KEY"
resource "aws_secretsmanager_secret" "knowbe4_api_key" {
  name        = "sym/${local.environment_name}/knowbe4-api-key"
  description = "API Key for Sym to call KnowBe4 APIs"

  # This SymEnv tag is required and MUST match the SymEnv tag in the
  # aws_iam_policy.secrets_manager_access in your `secrets.tf` file
  tags = {
    SymEnv = local.environment_name
  }
}

# This resources tells Sym how to access your KnowBe4 API Key.
resource "sym_secret" "knowbe4_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.knowbe4_api_key.name
}

# A KnowBe4 Integration that can be included in your `sym_environment` to enable `sym.sdk.integrations.knowbe4` methods
resource "sym_integration" "knowbe4" {
  type        = "knowbe4"
  name        = "${local.environment_name}-knowbe4-integration"

  # KnowBe4 domain, get the primary domain from the domains list from the Admin portal UI
  external_id = "primary-domain.io"

  settings = {
    # `type=knowbe4` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your KnowBe4 API Key
    api_token_secret = sym_secret.knowbe4_api_key.id
    # `type=knowbe4` sym_integrations have a required setting `region`,
    # which must be one of ["us", "eu", "ca", "uk", "de"]
    region = "us"
  }
}
