/*
 * Create an example S3 bucket that we will manage access to with Sym and K9!
 */
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.5.0"

  bucket_prefix = "sym-target-"
  acl           = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = var.tags
}

/*
 * Look up the IAM Roles for our permission sets that are generated by IAM
 * Identity Center
 */
data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AWSAdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "s3_role" {
  name_regex  = "AWSReservedSSO_${aws_ssoadmin_permission_set.s3_access.name}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"

  depends_on = [
    # Depend on our account assignment to ensure the role exists before we try to find it
    aws_ssoadmin_account_assignment.s3_access
  ]
}

# Set up the principal ARNs that will be able to work with our target S3 bucket
locals {
  administrator_arns = [
    one(data.aws_iam_roles.admin_role.arns)
  ]

  read_config_arns = local.administrator_arns

  read_data_arns = [
    one(data.aws_iam_roles.s3_role.arns)
  ]

  write_data_arns = local.read_data_arns
}

/*
 * Use K9's bucket policy module to provision a least-privilege bucket policy that only
 * grants the administrator and the s3_access permission sets access to the bucket.
 */
module "k9_bucket_policy" {
  source  = "k9securityio/s3-bucket/aws//k9policy"
  version = "0.7.3"

  s3_bucket_arn = module.s3_bucket.s3_bucket_arn

  allow_administer_resource_arns = local.administrator_arns
  allow_read_config_arns         = local.read_config_arns
  allow_read_data_arns           = local.read_data_arns
  allow_write_data_arns          = local.write_data_arns
}

resource "aws_s3_bucket_policy" "this" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = module.k9_bucket_policy.policy_json
}