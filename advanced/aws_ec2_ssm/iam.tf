data "aws_ssoadmin_instances" "this" {
  provider = aws.sso
}

# Create an AWS SSO PermissionSet that allows Session Manager access
# to EC2 instances tagged with Department=FrontEnd
resource "aws_ssoadmin_permission_set" "frontend_ssh" {
  name             = "FrontEndSSHAccess"
  description      = "Access to SSH to FrontEnd instances"
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = "PT2H"

  provider = aws.sso

  tags = var.tags
}

# Customer managed policies are attached using their name. You need to make
# sure the managed policy actually exists in any account you try to provision
# this into
resource "aws_ssoadmin_customer_managed_policy_attachment" "frontend_ssh" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.frontend_ssh.arn

  customer_managed_policy_reference {
    name = aws_iam_policy.frontend_ssh.name
    path = aws_iam_policy.frontend_ssh.path
  }

  provider = aws.sso
}

# Provision the customer-managed policy in the target AWS account
# where we will be testing.
resource "aws_iam_policy" "frontend_ssh" {
  name   = "frontend_ssh"
  path   = "/sym/"
  policy = data.aws_iam_policy_document.frontend_ssh.json

  tags = var.tags
}

# Allow ssh into instances tagged with Department=Frontend
data "aws_iam_policy_document" "frontend_ssh" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession", "ssm:SendCommand"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ssm:resourceTag/Department"
      values   = ["FrontEnd"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceInformation",
      "ssm:DescribeInstanceProperties",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
  # Use a session tag to determine who can terminate the instance
  # since we are dealing with federated users.
  statement {
    effect    = "Allow"
    actions   = ["ssm:TerminateSession", "ssm:ResumeSession"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ssm:resourceTag/aws:ssmmessages:session-id"
      values   = ["$${aws:userid}"]
    }
  }
}
