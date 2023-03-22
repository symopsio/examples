# An AWS Secrets Manager Secret to hold your PagerDuty API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/pagerduty-api-key" --secret-string "YOUR-PAGERDUTY-API-KEY"
resource "aws_secretsmanager_secret" "pagerduty_api_key" {
  name        = "main/pagerduty-api-key"
  description = "API Key for Sym to call PagerDuty APIs"

  # This SymEnv tag is required and MUST match the SymEnv tag in the 
  # aws_iam_policy.secrets_manager_access in your `secrets.tf` file
  tags = {
    SymEnv = local.environment_name
  }
}

# This resources tells Sym how to access your PagerDuty API Key.
resource "sym_secret" "pagerduty_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.pagerduty_api_key.name
}

# A PagerDuty Integration that can be included in your `sym_environment` to enable `sym.sdk.integrations.pagerduty` methods
resource "sym_integration" "pagerduty" {
  type        = "pagerduty"
  name        = "main-pagerduty-integration"
  external_id = "sym-example.pagerduty.com"

  settings = {
    # `type=pagerduty` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your PagerDuty API Key
    api_token_secret = sym_secret.pagerduty_api_key.id
  }
}

############ Basic Approval Flow ##############

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = "${path.module}/impl.py"

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "resource"
      label    = "What do you need access to?"
      type     = "string"
      required = true
    }

    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }
  }
}
