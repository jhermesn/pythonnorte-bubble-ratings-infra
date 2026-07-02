# pythonnorte-bubble-ratings-infra

Terraform IaC for the CI/CD pipeline demo at **Python Norte 2026**.

App: [pythonnorte-bubble-ratings-app](https://github.com/jhermesn/pythonnorte-bubble-ratings-app)

## Setup

```bash
# 1. Once, manually, with your own AWS credentials (creates the S3 state bucket):
terraform -chdir=_bootstrap init && terraform -chdir=_bootstrap apply

# 2. Add repo secret AWS_INFRA_DEPLOY_ROLE_ARN (OIDC role, least-privilege)

# 3. Run "Provision Infrastructure" (workflow_dispatch)
```

`provision` publishes resource identifiers to SSM under `/pythonnorte-bubble-ratings/*`; the app
repo's `cd.yml` reads them from there.

Run "Destroy Infrastructure" (`workflow_dispatch`, requires typing `destroy` to confirm) to tear
everything down.
