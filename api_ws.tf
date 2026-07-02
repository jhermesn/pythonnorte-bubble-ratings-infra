module "ws_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.1.0"

  name                       = "${var.project_name}-ws"
  description                = "WebSocket API broadcasting new comments in real time"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  create_domain_name = false

  # Required for WEBSOCKET APIs: the module's stage config errors without an
  # explicit logging_level (no built-in default for this protocol type).
  stage_default_route_settings = {
    logging_level = "OFF"
  }

  # Not needed for a demo app; avoids the separate CloudWatch resource
  # policy access logging requires (distinct from the account-level
  # execution-logging role).
  stage_access_log_settings = null

  routes = {
    "$connect" = {
      integration = {
        uri                    = module.lambda_ws_connect.lambda_function_invoke_arn
        payload_format_version = "1.0"
      }
    }
    "$disconnect" = {
      integration = {
        uri                    = module.lambda_ws_disconnect.lambda_function_invoke_arn
        payload_format_version = "1.0"
      }
    }
  }
}
