terraform {
  required_version = "~> 1.15.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.53.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.14.1"

  bucket = var.state_bucket_name

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

data "aws_caller_identity" "current" {}

# Reuses the account's existing GitHub OIDC provider instead of creating a
# second one (only one can exist per URL per account).
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "infra_deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.project_name}-infra:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "infra_deploy" {
  name               = "${var.project_name}-infra-deploy"
  assume_role_policy = data.aws_iam_policy_document.infra_deploy_assume.json
}

data "aws_iam_policy_document" "infra_deploy_permissions" {
  statement {
    sid       = "TerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn, "${module.state_bucket.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "DynamoDbTables"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
      "dynamodb:UpdateTable", "dynamodb:TagResource", "dynamodb:UntagResource",
      "dynamodb:ListTagsOfResource", "dynamodb:DescribeTimeToLive", "dynamodb:UpdateTimeToLive",
      "dynamodb:DescribeContinuousBackups", "dynamodb:UpdateContinuousBackups",
    ]
    resources = ["arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-*"]
  }

  statement {
    sid    = "LambdaFunctions"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction", "lambda:DeleteFunction", "lambda:GetFunction",
      "lambda:GetFunctionConfiguration", "lambda:UpdateFunctionConfiguration",
      "lambda:TagResource", "lambda:UntagResource", "lambda:ListTags",
      "lambda:AddPermission", "lambda:RemovePermission", "lambda:GetPolicy",
      "lambda:CreateEventSourceMapping", "lambda:DeleteEventSourceMapping",
      "lambda:GetEventSourceMapping", "lambda:UpdateEventSourceMapping",
      "lambda:ListEventSourceMappings",
    ]
    resources = ["arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"]
  }

  statement {
    sid    = "LambdaExecutionRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:TagRole", "iam:UntagRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
  }

  statement {
    sid       = "PassLambdaExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid    = "LambdaLogGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:PutRetentionPolicy",
      "logs:TagResource", "logs:UntagResource", "logs:ListTagsForResource",
      "logs:DescribeLogGroups",
    ]
    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*"]
  }

  statement {
    sid       = "ApiGateway"
    effect    = "Allow"
    actions   = ["apigateway:GET", "apigateway:POST", "apigateway:PUT", "apigateway:PATCH", "apigateway:DELETE"]
    resources = ["arn:aws:apigateway:*::/apis", "arn:aws:apigateway:*::/apis/*", "arn:aws:apigateway:*::/tags/*"]
  }

  statement {
    sid       = "FrontendBucket"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.project_name}-frontend-*", "arn:aws:s3:::${var.project_name}-frontend-*/*"]
  }

  statement {
    sid    = "CloudFrontManage"
    effect = "Allow"
    actions = [
      "cloudfront:GetDistribution", "cloudfront:UpdateDistribution", "cloudfront:DeleteDistribution",
      "cloudfront:TagResource", "cloudfront:UntagResource", "cloudfront:ListTagsForResource",
      "cloudfront:GetOriginAccessControl", "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
    ]
    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*",
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*",
    ]
  }

  statement {
    sid       = "CloudFrontCreate"
    effect    = "Allow"
    actions   = ["cloudfront:CreateDistribution", "cloudfront:CreateOriginAccessControl"]
    resources = ["*"]
  }

  statement {
    sid    = "SsmParameters"
    effect = "Allow"
    actions = [
      "ssm:PutParameter", "ssm:GetParameter", "ssm:GetParameters", "ssm:DeleteParameter",
      "ssm:AddTagsToResource", "ssm:ListTagsForResource",
    ]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"]
  }
}

resource "aws_iam_role_policy" "infra_deploy" {
  name   = "${var.project_name}-infra-deploy-policy"
  role   = aws_iam_role.infra_deploy.id
  policy = data.aws_iam_policy_document.infra_deploy_permissions.json
}

data "aws_iam_policy_document" "app_deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.project_name}-app:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "app_deploy" {
  name               = "${var.project_name}-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_assume.json
}

data "aws_iam_policy_document" "app_deploy_permissions" {
  statement {
    sid       = "ReadSsmParameters"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"]
  }

  statement {
    sid       = "DeployLambdaCode"
    effect    = "Allow"
    actions   = ["lambda:UpdateFunctionCode", "lambda:GetFunction", "lambda:GetFunctionConfiguration"]
    resources = ["arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"]
  }

  statement {
    sid       = "SyncFrontendBucket"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.project_name}-frontend-*", "arn:aws:s3:::${var.project_name}-frontend-*/*"]
  }

  statement {
    sid       = "InvalidateCloudFront"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"]
  }
}

resource "aws_iam_role_policy" "app_deploy" {
  name   = "${var.project_name}-app-deploy-policy"
  role   = aws_iam_role.app_deploy.id
  policy = data.aws_iam_policy_document.app_deploy_permissions.json
}
