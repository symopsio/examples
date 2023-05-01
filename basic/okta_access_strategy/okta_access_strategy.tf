# An AWS Secrets Manager Secret to hold your Okta API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/okta/okta-api-key" --secret-string "YOUR-OKTA-API-KEY"
resource "aws_secretsmanager_secret" "okta_api_key" {
  name        = "sym/okta/okta-api-key"
  description = "API Key for Sym to call Okta APIs"

  tags = {
    # This SymEnv tag is required and MUST match the SymEnv tag in the
    # aws_iam_policy.secrets_manager_access in your `secrets.tf` file
    SymEnv = local.environment_name
  }
}

# This resource tells Sym how to access your Okta API Key.
resource "sym_secret" "okta_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # Name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.okta_api_key.name
}

# The Okta Integration that your Sym Strategy uses to manage your Okta targets
resource "sym_integration" "okta" {
  type        = "okta"
  name        = "${local.environment_name}-okta-integration"
  external_id = "dev-12345.okta.com"

  settings = {
    # `type=okta` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your Okta API Key
    api_token_secret = sym_secret.okta_api_key.id
  }
}

# A target Okta group that your Sym Strategy can manage access to
resource "sym_target" "okta_admin_access" {
  type  = "okta_group"
  name  = "${local.environment_name}-admin-access"
  label = "Admin Access"

  settings = {
    # `type=okta_group` sym_targets have a required setting `group_id`,
    # which must be the Group ID the requester will be escalated to when this target is selected.

    # The GroupID is visible while in the Okta Admin console, with the Group selected, in the URL of the browser.
    # Directory > Groups > Select the Group > the ID at the end of the browser's URL.
    group_id = "00g12345xxx"
  }
}

# A target Okta group that your Sym Strategy can manage access to
resource "sym_target" "okta_s3_access" {
  type  = "okta_group"
  name  = "${local.environment_name}-s3-access"
  label = "S3 Write Access"

  settings = {
    # `type=okta_group` sym_targets have a required setting `group_id`,
    # which must be the Group ID the requester will be escalated to when this target is selected.

    # The GroupID is visible while in the Okta Admin console, with the Group selected, in the URL of the browser.
    # Directory > Groups > Select the Group > the ID at the end of the browser's URL.
    group_id = "00g67890xxx"
  }
}

# The Strategy your Flow uses to escalate to Okta Groups
resource "sym_strategy" "okta" {
  type           = "okta"
  name           = "${local.environment_name}-okta-strategy"
  integration_id = sym_integration.okta.id

  # This must be a list of `okta_group` sym_target that users can request to be escalated to
  targets = [sym_target.okta_admin_access.id, sym_target.okta_s3_access.id]
}

resource "sym_flow" "this" {
  name  = "okta"
  label = "Okta Group Request"

  implementation = "${path.module}/impl.py"

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.okta.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }

    prompt_field {
      name           = "duration"
      type           = "duration"
      allowed_values = ["30m", "1h"]
      required       = true
    }
  }
}
