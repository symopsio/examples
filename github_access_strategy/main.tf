provider "sym" {
  org = "sym-example"
}

############ General AWS Secrets Manager Setup ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "terraform.symops.com/symopsio/runtime-connector/sym"
  version = ">= 1.1.0"

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

############ GitHub Integration and Secret Setup ##############

# An AWS Secrets Manager Secret to hold your GitHub Access Token. Set the value with:
# aws secretsmanager put-secret-value --secret-id "main/github-access-token" --secret-string "YOUR-GITHUB-ACCESS-TOKEN"
resource "aws_secretsmanager_secret" "github_access_token" {
  name        = "main/github-access-token"
  description = "API Key for Sym to call GitHub APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
  }
}

# This resource tells Sym how to access your GitHub Access Key.
resource "sym_secret" "github_access_token" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # Name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.github_access_token.name
}

# The GitHub Integration that your Sym Strategy uses to manage your GitHub Repo targets
resource "sym_integration" "github" {
  type = "github"
  name = "main-github-integration"

  # The external ID is your GitHub Organization name
  external_id = "sym-test"

  settings = {
    # `type=github` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your GitHub Access Token
    api_token_secret = sym_secret.github_access_token.id
  }
}

############ GitHub Strategy Setup ##############

# A target GitHub repo that your Sym Strategy can manage access to
resource "sym_target" "private-repo" {
  type = "github_repo"

  name  = "main-private-repo-access"
  label = "Private Repo"

  settings = {
    # `type=github_repo` sym_targets have a required setting `repo_nae`,
    # which must be name of the Repository the requester will be escalated to when this target is selected
    repo_name = "private-repo"
  }
}

# A target GitHub repo that your Sym Strategy can manage access to
resource "sym_target" "other-private-repo" {
  type = "github_repo"

  name  = "main-other-private-repo-access"
  label = "Other Private Repo"

  settings = {
    # `type=github_repo` sym_targets have a required setting `repo_nae`,
    # which must be name of the Repository the requester will be escalated to when this target is selected
    repo_name = "other-private-repo"
  }
}

# The Strategy your Flow uses to escalate to GitHub Repositories
resource "sym_strategy" "github" {
  type           = "github"
  name           = "main-github-strategy"
  integration_id = sym_integration.github.id

  # This must be a list of `github_repo` sym_targets that users can request to be escalated to
  targets = [sym_target.private-repo.id, sym_target.other-private-repo.id]
}

resource "sym_flow" "this" {
  name  = "github"
  label = "GitHub Repo Access"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.github.id

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
        allowed_values = ["1h", "1d", "10d"]
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

    # The GitHub Access Token is implicitly available to your GitHub Flow's impl.py,
    # so this line is optional if you only need to use `sym.sdk.integrations.github` methods in your GitHub Flow.
    #
    # But if you wish to use the `sym.sdk.integrations.github` methods in a different Flow in this Environment,
    # you must include this `github_id = sym_integration.github.id` here.
    github_id = sym_integration.github.id
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
