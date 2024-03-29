terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    sym = {
      source  = "symopsio/sym"
      version = "~> 3.0"
    }
  }
}
