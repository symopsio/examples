############ IAM Strategy Setup ##############

# A target AWS IAM Group that your Sym Strategy can manage access to
resource "sym_target" "cloudwatch_readonly" {
  type = "aws_iam_group"

  # Your AWS IAM Group. This sample group is defined in iam.tf
  # Users in this group are given permissions to access cloudwatch
  name  = aws_iam_group.cloudwatch_readonly.name
  label = "Cloudwatch Read-only"

  settings = {
    # `type=aws_iam_group` sym_targets have a required setting `iam_group`,
    # which must be the name of the IAM Group the user will be added to.
    iam_group = aws_iam_group.cloudwatch_readonly.name
  }
}

# The Strategy your Flow uses to escalate to AWS IAM Groups
resource "sym_strategy" "aws_iam" {
  type           = "aws_iam"
  name           = "${local.environment_name}-aws-iam"
  integration_id = sym_integration.iam_context.id

  # This must be a list of `aws_iam_group` sym_targets that users can request to be escalated to
  targets = [sym_target.cloudwatch_readonly.id]
}

resource "sym_flow" "this" {
  name  = "aws_iam"
  label = "AWS IAM Group Access"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.aws_iam.id

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
