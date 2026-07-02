locals {
  ssm_prefix = "/${var.project_name}"
}

resource "aws_ssm_parameter" "frontend_bucket_name" {
  name  = "${local.ssm_prefix}/frontend_bucket_name"
  type  = "String"
  value = module.frontend_bucket.s3_bucket_id
}

resource "aws_ssm_parameter" "frontend_distribution_id" {
  name  = "${local.ssm_prefix}/frontend_distribution_id"
  type  = "String"
  value = module.frontend_cdn.cloudfront_distribution_id
}

resource "aws_ssm_parameter" "frontend_url" {
  name  = "${local.ssm_prefix}/frontend_url"
  type  = "String"
  value = "https://${module.frontend_cdn.cloudfront_distribution_domain_name}"
}

resource "aws_ssm_parameter" "http_api_url" {
  name  = "${local.ssm_prefix}/http_api_url"
  type  = "String"
  value = module.http_api.api_endpoint
}

resource "aws_ssm_parameter" "ws_api_url" {
  name  = "${local.ssm_prefix}/ws_api_url"
  type  = "String"
  value = module.ws_api.api_endpoint
}

resource "aws_ssm_parameter" "lambda_http_api_function_name" {
  name  = "${local.ssm_prefix}/lambda/http_api_function_name"
  type  = "String"
  value = module.lambda_http_api.lambda_function_name
}

resource "aws_ssm_parameter" "lambda_ws_connect_function_name" {
  name  = "${local.ssm_prefix}/lambda/ws_connect_function_name"
  type  = "String"
  value = module.lambda_ws_connect.lambda_function_name
}

resource "aws_ssm_parameter" "lambda_ws_disconnect_function_name" {
  name  = "${local.ssm_prefix}/lambda/ws_disconnect_function_name"
  type  = "String"
  value = module.lambda_ws_disconnect.lambda_function_name
}

resource "aws_ssm_parameter" "lambda_broadcast_function_name" {
  name  = "${local.ssm_prefix}/lambda/broadcast_function_name"
  type  = "String"
  value = module.lambda_broadcast.lambda_function_name
}
