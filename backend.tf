terraform {
  backend "s3" {
    bucket       = "pythonnorte-bubble-ratings-tfstate"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
