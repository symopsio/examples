# Sample IAM Groups you wish to manage access to

# An AWS IAM Group that grants Cloudwatch Read permissions
resource "aws_iam_group" "cloudwatch_readonly" {
  name = "main-cloudwatch-read"
  path = "/sym/"
}

# Declare the IAM Policy
resource "aws_iam_policy" "cloudwatch_readonly" {
  name   = "cloudwatch-readonly-policy"
  path   = "/sym/"
  policy = data.aws_iam_policy_document.cloudwatch_readonly.json
}

# Define the IAM Policy Statement
data "aws_iam_policy_document" "cloudwatch_readonly" {
  statement {
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Get*",
      "logs:List*",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:Describe*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
}

# Attach the IAM Policy to the IAM Group
resource "aws_iam_group_policy_attachment" "cloudwatch_readonly" {
  group      = aws_iam_group.cloudwatch_readonly.id
  policy_arn = aws_iam_policy.cloudwatch_readonly.id
}
