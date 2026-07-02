module "comments_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 5.5.0"

  name     = "${var.project_name}-comments"
  hash_key = "comment_id"

  attributes = [
    { name = "comment_id", type = "S" }
  ]

  billing_mode                   = "PAY_PER_REQUEST"
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
}
