variable "aws_region" {
  description = "AWS region where all resources are created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resource names"
  type        = string
  default     = "pythonnorte-bubble-ratings"
}
