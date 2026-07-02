output "frontend_url" {
  description = "Public HTTPS URL of the frontend (CloudFront)"
  value       = "https://${module.frontend_cdn.cloudfront_distribution_domain_name}"
}

output "http_api_url" {
  description = "Base URL of the HTTP API (GET/POST /comments)"
  value       = module.http_api.api_endpoint
}
