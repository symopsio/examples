locals {
  environment_name = "main"
}

provider "sym" {
  org = "sym-example"
}

# Set up this AWS provider for the AWS account where Sym's runtime and any other
# supporting resources for Sym can go, like reporting streams with AWS Kinesis.
provider "aws" {
  region = "us-east-1"
}

# Set up a different provider for the SSO connector.
# This is because you typically will put your Sym resources in a different
# AWS account from your AWS SSO instance.
provider "aws" {
  alias  = "sso"
  region = "us-east-1"

  # Change this profile name to a valid AWS profile for the AWS account where
  # your AWS SSO instance lives.
  profile = "sso"
}

# Get the AWS Account ID for the SSO profile.
data "aws_caller_identity" "sso" {
  provider = aws.sso
}

############ Giving Sym Runtime Permissions to Manage your AWS SSO Permission Sets ##############

# Creates an AWS IAM Role that the Sym Runtime can use for execution
# Allow the runtime to assume roles in the /sym/ path in your AWS Account
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  # Allow the runtime to assume roles in the AWS Account ID where your SSO instance is provisioned.
  account_id_safelist = [data.aws_caller_identity.sso.account_id]
  environment         = local.environment_name

  tags = var.tags
}

# The AWS IAM Resources that enable Sym to manage SSO Permission Sets
module "sso_connector" {
  source  = "symopsio/sso-connector/aws"
  version = "~> 2.0"

  # Provision the SSO connector in the AWS account where your AWS
  # SSO instance lives.
  providers = {
    aws = aws.sso
  }

  environment       = local.environment_name
  runtime_role_arns = [module.runtime_connector.sym_runtime_connector_role.arn]

  tags = var.tags
}

# The Integration your Strategy uses to manage SSO Permission Sets
resource "sym_integration" "sso_context" {
  type        = "permission_context"
  name        = "${local.environment_name}-sso"
  external_id = module.sso_connector.settings["instance_arn"]
  settings    = module.sso_connector.settings
}

############ SSO Strategy Setup ##############

# Get the AWS Account ID for the main AWS profile.
data "aws_caller_identity" "main" {}


# A Sym Target that will grant users FrontEnd SSH access in the given AWS account
resource "sym_target" "frontend_ssh" {
  type = "aws_sso_permission_set"

  name  = "frontend-ssh"
  label = "FrontEnd SSH"

  settings = {
    # `type=aws_sso_permission_set` sym_targets need both an AWS Permission Set
    # ARN and an AWS Account ID to make an sso account assignment
    permission_set_arn = aws_ssoadmin_permission_set.frontend_ssh.arn
    account_id         = data.aws_caller_identity.main.account_id
  }
}

# The Strategy your Flow uses to escalate to AWS SSO Permission Sets
resource "sym_strategy" "aws_sso" {
  type           = "aws_sso"
  name           = "${local.environment_name}-aws-sso"
  integration_id = sym_integration.sso_context.id

  # This must be a list of `aws_sso_permission_set` sym_targets that users can request to be escalated to
  targets = [sym_target.frontend_ssh.id]

  settings = {
    instance_arn = module.sso_connector.settings["instance_arn"]
  }
}

resource "sym_flow" "this" {
  name  = "aws_sso"
  label = "AWS SSO Access"

  implementation = file("${path.module}/impl.py")
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


############ Basic Environment Setup ##############

# The sym_environment is a container for sym_flows that share configuration values
# (e.g. shared integrations or error logging)
resource "sym_environment" "this" {
  name            = local.environment_name
  runtime_id      = module.runtime_connector.sym_runtime.id
  error_logger_id = sym_error_logger.slack.id

  integrations = {
    slack_id = sym_integration.slack.id
  }
}

resource "sym_integration" "slack" {
  type = "slack"
  name = "${local.environment_name}-slack"

  # The external_id for slack integrations is the Slack Workspace ID
  external_id = "T123ABC"
}

# This sym_error_logger will output any warnings and errors that occur during
# execution of a sym_flow to a specified channel in Slack.
resource "sym_error_logger" "slack" {
  integration_id = sym_integration.slack.id
  destination    = "#sym-errors"
}
