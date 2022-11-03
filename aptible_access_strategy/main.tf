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

############ Aptible Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your Aptible Bot Token. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/aptible-bot-credentials" --secret-string '{"username":"YOUR_BOT_USERNAME","password":"YOUR_BOT_TOKEN"}'
resource "aws_secretsmanager_secret" "aptible_bot_credentials" {
  name        = "main/aptible-bot-credentials"
  description = "API Key for Sym to call Aptible APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
  }
}


# This resource tells Sym how to access your Aptible Bot username.
resource "sym_secret" "aptible_bot_username" {
  source_id = sym_secrets.this.id
  path      = aws_secretsmanager_secret.aptible_bot_credentials.name

  settings = {
    json_key = "username" # The key to to the bot user's username in your JSON secret
  }
}

# This resource tells Sym how to access your Aptible Bot password.
resource "sym_secret" "aptible_bot_password" {
  source_id = sym_secrets.this.id
  path      = aws_secretsmanager_secret.aptible_bot_credentials.name

  settings = {
    json_key = "password" # The key to the bot user's password in your JSON secret
  }

  depends_on = [
    sym_secret.aptible_bot_username
  ]
}

# The Aptible Integration that your Sym Strategy uses to manage your Aptible Roles targets
resource "sym_integration" "aptible" {
  type = "aptible"
  name = "main-aptible-integration"

  # Your Aptible Organization ID
  external_id = "94a49e57-d046-4d9d-9dbf-f7711e337368"

  settings = {
    # `type=aptible` sym_integrations have required settings `username_secret` and `password_secret`,
    # which must point to sym_secrets referencing your Aptible bot credentials
    username_secret = sym_secret.aptible_bot_username.id
    password_secret = sym_secret.aptible_bot_password.id
  }
}

############ Aptible Strategy Setup ##############

# A target Aptible Role that your Sym Strategy can manage access to
resource "sym_target" "admin_prod" {
  type = "aptible_role"

  name  = "main-aptible-admin-role"
  label = "Admin Role"
  settings = {
    # You can find the role IDs by going to the Aptible dashboard and selecting a role. The ID will then be in the URL.
    role_id = "24463EF7-1D6E-402E-A365-69CB6DB80C6E"
  }
}

# A target Aptible Role that your Sym Strategy can manage access to
resource "sym_target" "admin_ro" {
  type = "aptible_role"

  name  = "main-aptible-read-only-role"
  label = "Read Only Role"

  settings = {
    role_id = "C7D5F21A-1D4E-4B39-9957-F8ACABDE2A3A"
  }
}

# The Strategy your Flow uses to escalate to Aptible Roles
resource "sym_strategy" "aptible" {
  type = "aptible"
  name = "main-aptible-strategy"

  # When this strategy is run, Sym Runtime will use the credentials specified
  # in this integration to call Aptible APIs.
  integration_id = sym_integration.aptible.id

  # These are the targets that will be listed when a Flow with this strategy is run.
  targets = [sym_target.admin_prod.id, sym_target.admin_ro.id]
}

resource "sym_flow" "this" {
  name  = "aptible"
  label = "Aptible Access"

  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.aptible.id

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
