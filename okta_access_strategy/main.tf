provider "sym" {
  org = "sym-example"
}

provider "aws" {
  region = "us-east-1"
}

############ General AWS Secrets Manager Setup ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/sym"
  version = ">= 1.0.0"

  # The aws/secretsmgr addon is required to access secrets
  addons = ["aws/secretsmgr"]

  environment = "main"
}

# An Integration that tells the Sym Runtime resource which AWS Role to assume
# (The AWS Role created by the runtime_connector module)
resource "sym_integration" "runtime_context" {
  type = "permission_context"
  name = "main-runtime"

  external_id = module.runtime_connector.settings.account_id
  settings    = module.runtime_connector.settings
}

# This resource tells Sym which role to use to access your AWS Secrets Manager
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "main-sym-secrets"

  settings = {
    context_id = sym_integration.runtime_context.id
  }
}

############ Okta Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your Okta API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/okta-api-key" --secret-string "YOUR-OKTA-API-KEY"
resource "aws_secretsmanager_secret" "okta_api_key" {
  name        = "main/okta-api-key"
  description = "API Key for Sym to call Okta APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
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

############ Okta Strategy Setup ##############

# A target Okta group that your Sym Strategy can manage access to
resource "sym_target" "okta_admin_access" {
  type  = "okta_group"
  name  = "main-admin-access"
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
  name  = "main-s3-access"
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
  name           = "main-okta-strategy"
  integration_id = sym_integration.okta.id

  # This must be a list of `okta_group` sym_target that users can request to be escalated to
  targets = [sym_target.okta_admin_access.id, sym_target.okta_s3_access.id]
}

resource "sym_flow" "this" {
  name  = "okta"
  label = "Okta Group Request"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.okta.id

    # prompt_fields_json defines custom form fields for the Slack modal that
    # requesters fill out to make their requests.
    prompt_fields_json = jsonencode([
      {
        name     = "reason"
        label    = "Why do you need access?"
        type     = "string"
        required = true
      },
      {
        name           = "duration"
        type           = "duration"
        allowed_values = ["30m", "1h"]
        required       = true
      }
    ])
  }
}
############ Basic Environment Setup ##############

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = "main"
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id

    # The Okta API Key is implicitly available to your Okta Flow's impl.py,
    # so this line is optional if you only need to use `sym.sdk.integrations.okta` methods in your Okta Flow.
    #
    # But if you wish to use the `sym.sdk.integrations.okta` methods in a different Flow in this Environment,
    # you must include this `okta_id = sym_integration.okta.id` here.
    okta_id = sym_integration.okta.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

  # The external_id for slack integrations is the Slack Workspace ID
  external_id = "T123ABC"
}

# This sym_error_logger will output any warnings and errors that occur during
# execution of a sym_flow to a specified channel in Slack.
resource "sym_error_logger" "slack" {
  integration_id = sym_integration.slack.id
  destination    = "#sym-errors"
}

resource "sym_runtime" "this" {
  name = "main"
}
