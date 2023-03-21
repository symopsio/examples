# The Okta Integration that your Sym Strategy uses to manage your Okta targets
resource "sym_integration" "okta" {
  type        = "okta"
  name        = "main-okta-integration"
  external_id = "dev-12345.okta.com"

  settings = {
    # `type=okta` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your Okta API Key
    api_token_secret = sym_secret.okta_api_key.id
  }
}

# An AWS Secrets Manager Secret to hold your Okta API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/okta-api-key" --secret-string "YOUR-OKTA-API-KEY"
resource "aws_secretsmanager_secret" "okta_api_key" {
  name        = "main/okta-api-key"
  description = "API Key for Sym to call Okta APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `name` in your `sym_environment` resource
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
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

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  vars = {
    # Replace this with the Okta Group ID (like 00g123456789) that we'll use in
    # the Flow implementation to check if the approving user is authorized to
    # approve this request.
    #
    # See our [docs](https://docs.symops.com/docs/okta#add-okta-access-targets)
    # for help on finding an Okta Group ID.
    approvers_group = "OKTA_GROUP_ID"
  }

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