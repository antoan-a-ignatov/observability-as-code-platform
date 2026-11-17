provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Project   = "observability-as-code-platform"
      Milestone = "M2"
    }
  }
}
