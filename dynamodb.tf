module "comments_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 5.5.0"

  name     = "${var.project_name}-comments"
  hash_key = "comment_id"

  attributes = [
    { name = "comment_id", type = "S" }
  ]

  billing_mode                   = "PAY_PER_REQUEST"
  stream_enabled                 = true # broadcast Lambda reacts to new INSERTs
  stream_view_type               = "NEW_IMAGE"
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
}

module "connections_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 5.5.0"

  name     = "${var.project_name}-connections"
  hash_key = "connection_id"

  attributes = [
    { name = "connection_id", type = "S" }
  ]

  billing_mode                   = "PAY_PER_REQUEST"
  ttl_enabled                    = true # purges connections that never got a clean $disconnect
  ttl_attribute_name             = "ttl"
  server_side_encryption_enabled = true
}
