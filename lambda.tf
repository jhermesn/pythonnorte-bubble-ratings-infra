# placeholder_src/ lets Terraform create these functions before real code exists;
# ignore_source_code_hash stops it from overwriting what the app repo's CD deploys.

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

  source_path             = "${path.module}/placeholder_src"
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

  allowed_triggers = {
    http_api = {
      service    = "apigateway"
      source_arn = "${module.http_api.api_execution_arn}/*/*"
    }
  }
}

module "lambda_ws_connect" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.8.0"

  function_name = "${var.project_name}-ws-connect"
  description   = "Registers a new WebSocket connection ($connect route)"
  handler       = "handlers.ws_connect.handler"
  runtime       = local.lambda_runtime
  architectures = local.lambda_architecture
  timeout       = 10

  source_path             = "${path.module}/placeholder_src"
  ignore_source_code_hash = true

  environment_variables = {
    CONNECTIONS_TABLE_NAME = module.connections_table.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    connections_put = {
      effect    = "Allow"
      actions   = ["dynamodb:PutItem"]
      resources = [module.connections_table.dynamodb_table_arn]
    }
  }

  allowed_triggers = {
    ws_api = {
      service    = "apigateway"
      source_arn = "${module.ws_api.api_execution_arn}/*/*"
    }
  }
}

module "lambda_ws_disconnect" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.8.0"

  function_name = "${var.project_name}-ws-disconnect"
  description   = "Removes a WebSocket connection ($disconnect route)"
  handler       = "handlers.ws_disconnect.handler"
  runtime       = local.lambda_runtime
  architectures = local.lambda_architecture
  timeout       = 10

  source_path             = "${path.module}/placeholder_src"
  ignore_source_code_hash = true

  environment_variables = {
    CONNECTIONS_TABLE_NAME = module.connections_table.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    connections_delete = {
      effect    = "Allow"
      actions   = ["dynamodb:DeleteItem"]
      resources = [module.connections_table.dynamodb_table_arn]
    }
  }

  allowed_triggers = {
    ws_api = {
      service    = "apigateway"
      source_arn = "${module.ws_api.api_execution_arn}/*/*"
    }
  }
}

module "lambda_broadcast" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.8.0"

  function_name = "${var.project_name}-broadcast"
  description   = "Broadcasts new comments to all connected WebSocket clients (DynamoDB Stream trigger)"
  handler       = "handlers.broadcast.handler"
  runtime       = local.lambda_runtime
  architectures = local.lambda_architecture
  timeout       = 30

  source_path             = "${path.module}/placeholder_src"
  ignore_source_code_hash = true

  environment_variables = {
    CONNECTIONS_TABLE_NAME = module.connections_table.dynamodb_table_id
    WS_MANAGEMENT_ENDPOINT = replace(module.ws_api.api_endpoint, "wss://", "https://")
  }

  attach_policy_statements = true
  policy_statements = {
    comments_stream_read = {
      effect = "Allow"
      actions = [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams",
      ]
      resources = [module.comments_table.dynamodb_table_stream_arn]
    }
    connections_rw = {
      effect    = "Allow"
      actions   = ["dynamodb:Scan", "dynamodb:DeleteItem"]
      resources = [module.connections_table.dynamodb_table_arn]
    }
    manage_ws_connections = {
      effect    = "Allow"
      actions   = ["execute-api:ManageConnections"]
      resources = ["${module.ws_api.api_execution_arn}/*/*/@connections/*"]
    }
  }

  event_source_mapping = {
    comments_stream = {
      event_source_arn  = module.comments_table.dynamodb_table_stream_arn
      starting_position = "LATEST"
      batch_size        = 10
    }
  }
}
