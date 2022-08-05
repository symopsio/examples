provider "sym" {
  org = "sym-example"
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

############ Tailscale Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your Tailscale API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/tailscale-api-key" --secret-string "YOUR-TAILSCALE-API-KEY"
resource "aws_secretsmanager_secret" "tailscale_api_key" {
  name        = "main/tailscale-api-key"
  description = "API Key for Sym to call Tailscale APIs"

  # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
  # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
  tags = {
    SymEnv = "main"
  }
}

# This resources tells Sym how to access your Tailscale API Key.
resource "sym_secret" "tailscale_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.tailscale_api_key.name
}

resource "sym_integration" "tailscale" {
  type        = "tailscale"
  name        = "main-tailscale-integration"
  external_id = "example.com" # The external_id is the unique name of your Tailscale network

  settings = {
    # `type=tailscale` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your Tailscale API Key
    api_token_secret = sym_secret.tailscale_api_key.id
  }
}


############ Tailscale Strategy Setup ##############

# A target Tailscale group that your Sym Strategy can manage access to
resource "sym_target" "tailscale_prod_group" {
  type  = "tailscale_group"
  name  = "main-prod-access"
  label = "Prod SSH Access"

  settings = {
    # `type=tailscale_group` sym_targets have a required setting `group_name`,
    # which must be the name of the Tailscale group the requester will be escalated to
    # when this target is selected.

    # The group name is defined in the "groups" section of your Tailscale Access Controls.
    # Tailscale > Admin > Access Controls > Groups
    group_name = "prod"
  }
}

# A target Tailscale group that your Sym Strategy can manage access to
resource "sym_target" "tailscale_staging_group" {
  type  = "tailscale_group"
  name  = "main-staging-access"
  label = "Staging SSH Access"

  settings = {
    # `type=tailscale_group` sym_targets have a required setting `group_name`,
    # which must be the name of the Tailscale group the requester will be escalated to
    # when this target is selected.

    # The group name is defined in the "groups" section of your Tailscale Access Controls.
    # Tailscale > Admin > Access Controls > Groups
    group_name = "staging"
  }
}

# The Strategy your Flow uses to escalate to Tailscale Groups
resource "sym_strategy" "tailscale" {
  type           = "tailscale"
  name           = "main-tailscale-strategy"
  integration_id = sym_integration.tailscale.id

  # This must be a list of `tailscale_group` sym_target that users can request to be escalated to
  targets = [sym_target.tailscale_prod_group.id, sym_target.tailscale_staging_group.id]
}

############ Flow Setup ##############

resource "sym_flow" "this" {
  name  = "tailscale-ssh-access"
  label = "Tailscale SSH Access"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.tailscale.id

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
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

  external_id = "T123ABC" # This external_id is your Slack Workspace ID
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
