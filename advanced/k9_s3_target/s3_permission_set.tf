data "aws_ssoadmin_instances" "this" {
  provider = aws.sso
}

# Create an AWS SSO PermissionSet that allows access to Sensitive S3 Buckets
resource "aws_ssoadmin_permission_set" "s3_access" {
  name             = "SymS3Access"
  description      = "Access to Sensitive S3 Buckets"
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = "PT2H"

  provider = aws.sso

  tags = var.tags
}

/*
 * The Permission Set doesn't actually need to grant access to S3, because we're
 * going to use K9 Security to generate a bucket policy that only lets this
 * permission set ARN read and write to the bucket.
 *
 * We're going to provide the managed ViewOnlyAccess policy which lets the
 * user poke around in the console.
 */
resource "aws_ssoadmin_managed_policy_attachment" "s3_access" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.s3_access.arn

  provider = aws.sso
}

/*
 * Look up an existing identity store group so that we can ensure our
 * permission set is provisioned in the target AWS account.
 */
data "aws_identitystore_group" "security_auditors" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = var.directory_group_name
  }

  provider = aws.sso
}

/*
 * Assign the S3 Access Permission Set to the security auditors group so
 * that Identity Center provisions the IAM role we need for our bucket
 * policy.
 */
resource "aws_ssoadmin_account_assignment" "s3_access" {
  instance_arn       = aws_ssoadmin_permission_set.s3_access.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.s3_access.arn

  principal_id   = data.aws_identitystore_group.security_auditors.group_id
  principal_type = "GROUP"

  target_id = data.aws_caller_identity.main.account_id

  target_type = "AWS_ACCOUNT"

  provider = aws.sso
}
