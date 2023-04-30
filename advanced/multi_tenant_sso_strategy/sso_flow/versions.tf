terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    sym = {
      source  = "symopsio/sym"
      version = "~> 2.0"
    }
  }
}
