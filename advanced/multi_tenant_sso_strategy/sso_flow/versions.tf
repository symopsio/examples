terraform {
  required_providers {
    sym = {
      source  = "symopsio/sym"
      version = "~> 2.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}
