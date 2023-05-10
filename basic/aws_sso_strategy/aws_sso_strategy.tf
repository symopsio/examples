############ SSO Strategy Setup ##############
# A target AWS SSO Permission Set Assignment that your Sym Strategy can manage access to
resource "sym_target" "power_user" {
  type = "aws_sso_permission_set"

  name  = "power-user"
  label = "AWS Power User"

  settings = {
    # `type=aws_sso_permission_set` sym_targets need both an AWS Permission Set
    # ARN and an AWS Account ID to make an sso account assignment
    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-aaaaaaaaaaaaaaaa/ps-aaaaaaaaaaaaaaaa"
    account_id         = "333333333333"
  }
}

# The Strategy your Flow uses to escalate to AWS SSO Permission Sets
resource "sym_strategy" "aws_sso" {
  type           = "aws_sso"
  name           = "${local.environment_name}-aws-sso"
  integration_id = sym_integration.sso_context.id

  # This must be a list of `aws_sso_permission_set` sym_targets that users can request to be escalated to
  targets = [sym_target.power_user.id]

  settings = {
    instance_arn = module.sso_connector.settings["instance_arn"]
  }
}

resource "sym_flow" "this" {
  name  = "aws_sso"
  label = "AWS SSO Access"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.aws_sso.id

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
