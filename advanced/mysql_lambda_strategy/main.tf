provider "aws" {
  region = "us-east-1"
}

# Optionally set up a database to use for testing the integration
module "db" {
  source = "./mysql_db"
  count  = var.db_enabled ? 1 : 0

  tags = var.tags
}
