resource "aws_iam_policy" "secrets_manager_access" {
  name = "SymSecretsManager${title(local.environment_name)}"
  path = "/sym/"

  description = "AWS IAM policy granting the Sym Runtime read-only permissions to Secrets Manager secrets tagged with `SymEnv = environment_name`."
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "*",
      "Condition": { "StringEquals": { "secretsmanager:ResourceTag/SymEnv": "${local.environment_name}" } }
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "attach_secrets_manager_access" {
  policy_arn = aws_iam_policy.secrets_manager_access.arn
  role       = module.runtime_connector.sym_runtime_connector_role.name
}

# This resource tells Sym how to access your AWS account's Secrets Manager instance.
resource "sym_secrets" "this" {
  type = "aws_secrets_manager"
  name = "${local.environment_name}-sym-secrets"

  settings = {
    # This tells Sym to use the sym_integration defined in the runtime_connector module when accessing
    # your AWS account's Secrets Manager.
    context_id = module.runtime_connector.sym_integration.id
  }
}
