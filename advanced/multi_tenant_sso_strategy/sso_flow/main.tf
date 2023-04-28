# The Integration the Sym Strategy uses to manage SSO Permission Sets and Groups
resource "sym_integration" "aws_sso_context" {
  type        = "permission_context"
  name        = "aws-sso-context-${var.tenant_slug}"
  external_id = var.sso_connector_settings.instance_arn
  settings    = var.sso_connector_settings
}

# A target AWS SSO Permission Set Assignment that your Sym Strategy can manage access to
resource "sym_target" "sso_permission_set" {
  type = "aws_sso_permission_set"

  name  = "multi-tenant-sso-permission-set-${var.tenant_slug}"
  label = title(var.tenant_slug)

  settings = {
    # `type=aws_sso_permission_set` sym_targets need both an AWS Permission Set
    # ARN and an AWS Account ID to make an SSO account assignment.
    permission_set_arn = var.permission_set_arn
    account_id         = var.account_id
  }
}

# The Strategy your Flow uses to create Account Assignments to AWS SSO Permission Sets/Account combinations
resource "sym_strategy" "multi_tenant_sso_aws_sso" {
  type           = "aws_sso"
  name           = "multi-tenant-aws-sso-strategy-${var.tenant_slug}"
  integration_id = sym_integration.aws_sso_context.id

  targets = [sym_target.sso_permission_set.id]

  settings = {
    instance_arn = var.sso_connector_settings.instance_arn
  }
}

resource "sym_flow" "multi_tenant_sso_aws_sso" {
  name  = "multi-tenant-sso-flow-${var.tenant_slug}"
  label = "AWS SSO Access (${title(var.tenant_slug)}"

  implementation = "${path.module}/impl.py"
  environment_id = var.sym_environment.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.multi_tenant_sso_aws_sso.id

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
