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
  source  = "symopsio/runtime-connector/aws"
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

############ OneLogin Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your OneLogin API Client Secret (the Client ID will be set below).
# Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/onelogin-client-secret" --secret-string "YOUR-ONELOGIN-CLIENT-SECRET"
resource "aws_secretsmanager_secret" "onelogin_client_secret" {
  name        = "main/onelogin-client-secret"
  description = "API Client Secret for Sym to call OneLogin APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
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
    role_id = "1234567"  # Replace this with your OneLogin Role's ID
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

############ Basic Environment Setup ##############

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = "main"
  runtime_id      = sym_runtime.this.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id

    # The OneLogin API Client ID and Secret is implicitly available to your OneLogin Flow's impl.py,
    # so this line is optional if you only need to use `sym.sdk.integrations.onelogin` methods with your OneLogin Flow.
    #
    # But if you wish to use the `sym.sdk.integrations.onelogin` methods in a different Flow in this Environment,
    # you must include this `onelogin_id = sym_integration.onelogin.id` here.
    onelogin_id = sym_integration.onelogin.id
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
