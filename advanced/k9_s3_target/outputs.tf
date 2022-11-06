output "bucket_arn" {
  description = "S3 Bucket ARN"
  value       = module.s3_bucket.s3_bucket_arn
}

output "permission_set_arn" {
  description = "S3 Access Permission Set Arn"
  value       = aws_ssoadmin_permission_set.s3_access.arn
}
