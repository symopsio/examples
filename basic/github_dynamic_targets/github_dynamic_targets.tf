# An AWS Secrets Manager Secret to hold your GitHub Access Token. Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/${local.environment_name}/github-access-token" --secret-string "YOUR-GITHUB-ACCESS-TOKEN"
resource "aws_secretsmanager_secret" "github_access_token" {
  name        = "sym/${local.environment_name}/github-access-token"
  description = "API Key for Sym to call GitHub APIs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` variable
    # passed into the `secrets_manager_access` module in your `secrets.tf` file
    SymEnv = local.environment_name
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
  name = "${local.environment_name}-github-integration"

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

  name  = "private-repos"
  label = "Private Repos"

  # A special attribute indicating which settings will be dynamically populated by prompt fields.
  # In this case, the setting is the required `repo_name` setting. The value will be populated by the
  # `repo_name` field in the `sym_flow.params.prompt_fields` attribute.
  field_bindings = ["repo_name"]
}

# The Strategy your Flow uses to escalate to GitHub Repositories
resource "sym_strategy" "github" {
  type           = "github"
  name           = "${local.environment_name}-github-strategy"
  integration_id = sym_integration.github.id

  # This must be a list of `github_repo` sym_targets that users can request to be escalated to
  targets = [sym_target.private-repo.id]
}

resource "sym_flow" "this" {
  name  = "github"
  label = "GitHub Repo Access"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.github.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      # This prompt_field will be used to populate the `repo_name` setting of the GitHub Access Target.
      # The name must match the setting name and type.
      name     = "repo_name"
      label    = "Repository Name"
      type     = "string"
      required = true

      # Setting prefetch = true means that this field's allowed values will be populated by
      # a prefetch reducer defined in the impl.py
      prefetch = true
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
