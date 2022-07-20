provider "aws" {
  region = var.aws_region
}

locals {
  rds_name        = "${var.namespace}-example"
  db_name         = "${var.namespace}_master"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"

  name = "symops"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = local.private_subnets
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = var.tags
}

module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 6.2.0"

  name          = local.rds_name
  database_name = local.db_name

  engine         = "aurora-postgresql"
  engine_version = "11.13"
  instance_class = var.db_instance_type
  instances = {
    one = {}
  }

  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.private_subnets
  allowed_cidr_blocks = local.private_subnets

  apply_immediately          = true
  monitoring_interval        = 0
  security_group_description = local.rds_name

  db_parameter_group_name         = aws_db_parameter_group.this.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id

  enabled_cloudwatch_logs_exports = ["postgresql"]

  skip_final_snapshot = true

  master_username        = local.db_name
  create_random_password = true

  tags = var.tags
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.rds_name}-postgres11"
  family      = "aurora-postgresql11"
  description = "${local.rds_name}-postgres11"
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${local.rds_name}-postgres11-cluster"
  family      = "aurora-postgresql11"
  description = "${local.rds_name}-postgres11-cluster"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "~> 0.30.0"

  ami_filter         = { "name" : ["amzn2-ami-hvm-*-x86_64-gp2"] }
  ami_owners         = ["amazon"]
  assign_eip_address = false
  instance_type      = "t2.micro"
  name               = "bastion"
  namespace          = var.namespace
  ssm_enabled        = true
  subnets            = module.vpc.private_subnets
  tags               = var.tags
  vpc_id             = module.vpc.vpc_id
}
