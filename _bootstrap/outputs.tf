output "state_bucket_name" {
  description = "Name of the S3 bucket created to store Terraform remote state"
  value       = module.state_bucket.s3_bucket_id
}
