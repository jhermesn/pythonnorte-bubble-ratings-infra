# placeholder.zip (built from placeholder_src/, checked in as a static artifact,
# never rebuilt automatically) lets Terraform create the function before real code
# exists. Using local_existing_package instead of source_path keeps the computed
# filename/hash stable across applies -- source_path rebuilds from the live
# directory on every apply, and any change to that directory (even unrelated
# files) changes the hash and triggers a real UpdateFunctionCode call, which the
# infra role deliberately can't make (only the app repo's CD deploys code).
# ignore_source_code_hash is still set so a rebuilt placeholder.zip never fights
# the real code the app repo deploys.

locals {
  lambda_runtime      = "python3.13"
  lambda_architecture = ["arm64"]
}

module "lambda_http_api" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.8.0"

  function_name = "${var.project_name}-http-api"
  description   = "Handles GET/POST /comments over the HTTP API"
  handler       = "handlers.http_api.handler"
  runtime       = local.lambda_runtime
  architectures = local.lambda_architecture
  timeout       = 10

  create_package          = false
  local_existing_package  = "${path.module}/placeholder.zip"
  ignore_source_code_hash = true

  environment_variables = {
    COMMENTS_TABLE_NAME = module.comments_table.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    comments_rw = {
      effect    = "Allow"
      actions   = ["dynamodb:PutItem", "dynamodb:Scan"]
      resources = [module.comments_table.dynamodb_table_arn]
    }
  }

  # We don't publish versions, so there's no "current version" to scope a
  # duplicate permission to; only the default $LATEST needs one.
  create_current_version_allowed_triggers = false

  allowed_triggers = {
    http_api = {
      service    = "apigateway"
      source_arn = "${module.http_api.api_execution_arn}/*/*"
    }
  }
}
