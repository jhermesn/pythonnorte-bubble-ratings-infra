module "frontend_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.14.1"

  # Bucket names are globally unique across all of AWS; suffixing with the
  # account id keeps this deterministic without needing a random suffix.
  bucket = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }
}

module "frontend_cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.7.0"

  comment             = "${var.project_name} frontend"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin_access_control = {
    frontend = {
      description      = "CloudFront access to the frontend S3 bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    frontend = {
      domain_name               = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "frontend"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

# Explicit grant for CloudFront's OAC: the s3-bucket module's own
# attach_policy input would create a circular dependency on the distribution ARN.
data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.frontend_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.frontend_cdn.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.frontend_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}
