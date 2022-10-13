locals {
  name   = "symdb"
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14"

  name = local.name
  cidr = "10.0.0.0/16"

  azs              = ["${local.region}a", "${local.region}b"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  create_database_subnet_group = true

  tags = var.tags
}

/*
 * Put the DB in a security group that allows ingress from 
 * the private subnets in the VPC
 */
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Sym Example DB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "mysql-tcp"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
    }
  ]

  tags = var.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.1"

  identifier = local.name

  engine               = "mysql"
  engine_version       = "5.7.39"
  family               = "mysql5.7" # DB parameter group
  major_engine_version = "5.7"      # DB option group
  instance_class       = "db.t3.micro"

  allocated_storage = 20

  db_name  = local.name
  username = local.name
  port     = 3306

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = var.tags
}

module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "~> 0.30.0"

  ami_filter         = { "name" : ["amzn2-ami-hvm-*-x86_64-gp2"] }
  ami_owners         = ["amazon"]
  assign_eip_address = false
  instance_type      = "t3a.micro"
  name               = "bastion"
  namespace          = local.name
  ssm_enabled        = true
  subnets            = module.vpc.private_subnets
  tags               = var.tags
  vpc_id             = module.vpc.vpc_id
}
