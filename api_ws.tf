module "ws_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.1.0"

  name                       = "${var.project_name}-ws"
  description                = "WebSocket API broadcasting new comments in real time"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  create_domain_name = false

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
