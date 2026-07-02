module "http_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.1.0"

  name          = "${var.project_name}-http"
  description   = "HTTP API for comments (GET/POST /comments)"
  protocol_type = "HTTP"

  create_domain_name = false

  # Not needed for a demo app; avoids the separate CloudWatch resource
  # policy access logging requires (distinct from the account-level
  # execution-logging role).
  stage_access_log_settings = null

  cors_configuration = {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["https://${module.frontend_cdn.cloudfront_distribution_domain_name}"]
    max_age       = 300
  }

  routes = {
    "GET /comments" = {
      integration = {
        uri                    = module.lambda_http_api.lambda_function_invoke_arn
        payload_format_version = "2.0"
      }
    }
    "POST /comments" = {
      integration = {
        uri                    = module.lambda_http_api.lambda_function_invoke_arn
        payload_format_version = "2.0"
      }
    }
  }
}
