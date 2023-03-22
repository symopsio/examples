# An AWS Secrets Manager Secret to hold your OneLogin API Client Secret (the Client ID will be set below).
# Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/onelogin-client-secret" --secret-string "YOUR-ONELOGIN-CLIENT-SECRET"
resource "aws_secretsmanager_secret" "onelogin_client_secret" {
  name        = "main/onelogin-client-secret"
  description = "API Client Secret for Sym to call OneLogin APIs"

  tags = {
    # This SymEnv tag is required and MUST match the SymEnv tag in the 
    # aws_iam_policy.secrets_manager_access in your `secrets.tf` file
    SymEnv = local.environment_name
  }
}

# This resource tells Sym how to access your OneLogin API Client Secret Key.
resource "sym_secret" "onelogin_client_secret" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # Name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.onelogin_client_secret.name
}

# The OneLogin Integration that your Sym Strategy uses to manage your OneLogin Role targets
resource "sym_integration" "onelogin" {
  type = "onelogin"
  name = "main-onelogin-integration"

  # The external ID is your OneLogin domain. Replace this value.
  external_id = "sym-example.onelogin.com"

  settings = {
    # `type=onelogin` sym_integrations have two required settings, for both
    # the API Client ID and Client Secret. Fill in your API Client ID below,
    # and remember to set the Client Secret in AWS Secrets Manager!
    client_id     = "0a1b2c3d4e5f67890a1b2c3d4e5f67890a1b2c3d4e5f6789"
    client_secret = sym_secret.onelogin_client_secret.id
  }
}

############ OneLogin Strategy Setup ##############

# A target OneLogin role that your Sym Strategy can manage access to
resource "sym_target" "onelogin_test_role" {
  type = "onelogin_role"

  name  = "onelogin-test-role"
  label = "OneLogin Test Role"

  settings = {
    role_id = "1234567" # Replace this with your OneLogin Role's ID
  }

  # A special attribute indicating which settings will be dynamically populated by prompt fields.
  # In this case, the setting is the required `privilege_level` setting. The value will be populated by a
  # `privilege_level` Prompt Field in the `sym_flow.params` attribute.
  field_bindings = ["privilege_level"]
}

# The Strategy your Flow uses to escalate to OneLogin Roles
resource "sym_strategy" "onelogin" {
  type           = "onelogin"
  name           = "main-onelogin-strategy"
  integration_id = sym_integration.onelogin.id

  # This must be a list of `onelogin_role` sym_targets that users can request to be escalated to
  targets = [sym_target.onelogin_test_role.id]
}

resource "sym_flow" "this" {
  name  = "onelogin"
  label = "OneLogin Role Access"

  implementation = "${path.module}/impl.py"

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.onelogin.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      # This prompt_field will be used to populate the `privilege_level` setting of the OneLogin Role Target.
      # The name must match the setting name. We also specify a restricted list of possible values, matching what
      # the Sym platform will accept for a OneLogin Role Target.
      name           = "privilege_level"
      label          = "Privilege Level"
      type           = "string"
      allowed_values = ["member", "admin"]
      required       = true
    }

    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }

    prompt_field {
      name           = "duration"
      type           = "duration"
      allowed_values = ["1h", "1d", "10d"]
      required       = true
    }
  }
}
