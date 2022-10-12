provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Optionally set up a database to use for testing the integration
module "db" {
  source = "./mysql_db"
  count  = var.db_enabled ? 1 : 0

  tags = var.tags
}
