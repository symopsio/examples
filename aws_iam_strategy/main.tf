provider "sym" {
  org = "sym-example"
}

############ Giving Sym Runtime Permissions to Manage your AWS IAM Groups ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "terraform.symops.com/symopsio/runtime-connector/sym"
  version = ">= 1.1.0"

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

# The AWS IAM Resources that enable Sym to manage IAM Groups
module "iam_connector" {
  source  = "terraform.symops.com/symopsio/iam-connector/sym"
  version = ">= 1.12.2"

  environment       = "main"
  runtime_role_arns = [module.runtime_connector.settings["role_arn"]]
}

# The Integration your Strategy uses to manage IAM Groups
resource "sym_integration" "iam_context" {
  type        = "permission_context"
  name        = "main-iam"
  external_id = module.iam_connector.settings.account_id
  settings    = module.iam_connector.settings
}

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
  name           = "main-aws-iam"
  integration_id = sym_integration.iam_context.id

  # This must be a list of `aws_iam_group` sym_targets that users can request to be escalated to
  targets = [sym_target.cloudwatch_readonly.id]
}

resource "sym_flow" "this" {
  name  = "aws_iam"
  label = "AWS IAM Group Access"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = sym_environment.this.id

  params = {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.aws_iam.id

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

  # Give the Sym Runtime the permissions defined by the runtime_connector module.
  context_id = sym_integration.runtime_context.id
}
