output "state_bucket_name" {
  description = "Name of the S3 bucket created to store Terraform remote state"
  value       = module.state_bucket.s3_bucket_id
}

output "infra_deploy_role_arn" {
  description = "ARN of the IAM role assumed by the infra repo's GitHub Actions workflows"
  value       = aws_iam_role.infra_deploy.arn
}

output "app_deploy_role_arn" {
  description = "ARN of the IAM role assumed by the app repo's GitHub Actions workflows"
  value       = aws_iam_role.app_deploy.arn
}
