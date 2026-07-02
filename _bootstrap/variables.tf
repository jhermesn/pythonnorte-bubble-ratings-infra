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

variable "project_name" {
  description = "Short name used as a prefix for all resource names and to derive GitHub repo names"
  type        = string
  default     = "pythonnorte-bubble-ratings"
}

variable "github_owner" {
  description = "GitHub org/user that owns the app and infra repos, used to scope OIDC trust"
  type        = string
  default     = "jhermesn"
}
