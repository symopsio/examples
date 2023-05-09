# An AWS Secrets Manager Secret to hold your Tailscale API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "${local.environment_name}/tailscale-api-key" --secret-string "YOUR-TAILSCALE-API-KEY"
resource "aws_secretsmanager_secret" "tailscale_api_key" {
  name        = "${local.environment_name}/tailscale-api-key"
  description = "API Key for Sym to call Tailscale APIs"

  # This SymEnv tag is required and MUST match the SymEnv tag in the
  # aws_iam_policy.secrets_manager_access in your `secrets.tf` file
  tags = {
    SymEnv = local.environment_name
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
  name        = "${local.environment_name}-tailscale-integration"
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
  name  = "${local.environment_name}-prod-access"
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
  name  = "${local.environment_name}-staging-access"
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
  name           = "${local.environment_name}-tailscale-strategy"
  integration_id = sym_integration.tailscale.id

  # This must be a list of `tailscale_group` sym_target that users can request to be escalated to
  targets = [sym_target.tailscale_prod_group.id, sym_target.tailscale_staging_group.id]
}

############ Flow Setup ##############

resource "sym_flow" "this" {
  name  = "tailscale-ssh-access"
  label = "Tailscale SSH Access"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.tailscale.id

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
