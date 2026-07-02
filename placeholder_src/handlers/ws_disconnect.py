"""Placeholder Lambda handler.

This infra repo only provisions the Lambda function shell (IAM role,
trigger, environment variables) with a handler entrypoint matching the
real application code's module path. The actual code is deployed
out-of-band by the pythonnorte-bubble-ratings-app repo's CD workflow via
`aws lambda update-function-code`, after this Terraform creates the
function. `ignore_source_code_hash = true` on every `lambda` module
instance tells Terraform to never revert the deployed code back to this
placeholder on a subsequent `terraform apply`.
"""


def handler(event, context):
    return {"statusCode": 501, "body": "Not deployed yet"}
