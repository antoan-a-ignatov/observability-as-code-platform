terraform {
  backend "s3" {
    bucket       = "observability-as-code-platform-tfstate-anto"
    key          = "foundation/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
