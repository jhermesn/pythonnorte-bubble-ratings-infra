variable "aws_region" {
  description = "AWS region where the Terraform state bucket is created"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique name of the S3 bucket used to store Terraform remote state"
  type        = string
  default     = "pythonnorte-bubble-ratings-tfstate"
}
