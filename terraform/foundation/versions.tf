terraform {
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}
