# An AWS Secrets Manager Secret to hold an API key necessary for making API calls to the third party system.
# Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/${local.environment_name}/api-key" --secret-string "YOUR-API-KEY"
resource "aws_secretsmanager_secret" "api_key" {
  name        = "sym/custom-strategy/api-key"
  description = "Key for accessing the third party system's API"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` variable
    # passed into the `secrets_manager_access` module in your `secrets.tf` file.
    SymEnv = local.environment_name
  }
}

# This resource tells Sym how to access your API key secret in AWS Secrets Manager.
resource "sym_secret" "api_key" {
  path      = aws_secretsmanager_secret.api_key.name
  source_id = sym_secrets.this.id
}

# The custom Integration that your Strategy uses to grant and revoke access to the
# third party system as well as manage identities for that system in Sym.
resource "sym_integration" "custom" {
  type = "custom"
  name = "custom-integration"

  # The external ID is a unique identifier for your account in the third party system.
  # For example, your account ID.
  external_id = "my-account"

  settings = {
    secret_ids_json = jsonencode([sym_secret.api_key.id])
  }
}

# A custom Target represents a resource a user is requesting access to.
resource "sym_target" "custom" {
  type  = "custom"
  name  = "custom-target"
  label = "Custom Target"

  settings = {
    identifier = "some-resource"
  }
}

# The Strategy that your Flow uses to grant and revoke access to the third party system.
resource "sym_strategy" "custom" {
  type = "custom"

  name           = "custom-access"
  integration_id = sym_integration.custom.id
  targets        = [sym_target.custom.id]

  # This implementation file contains Python code that defines escalation and deescalation behavior.
  implementation = "${path.module}/custom_strategy.py"
}

resource "sym_flow" "custom" {
  name  = "custom-access"
  label = "Custom Access"

  implementation = file("${path.module}/impl.py")
  environment_id = sym_environment.this.id

  params {
    strategy_id = sym_strategy.custom.id

    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }
  }
}
