# A managed policy that allows users to access their own Sym secrets.
# This policy should be configured as a customer-managed policy on
# an SSO permission set.
resource "aws_iam_policy" "sym_secrets" {
  name        = "SymSecretsAccess"
  description = "Allow users to access their own Sym secrets"
  path        = "/sym/"
  policy      = data.aws_iam_policy_document.sym_secrets.json

  tags = var.tags
}

# Allow users to access secrets tagged with their userid
data "aws_iam_policy_document" "sym_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = ["*:$${secretsmananager:ResourceTag/sym.user}"]
    }
  }
}
