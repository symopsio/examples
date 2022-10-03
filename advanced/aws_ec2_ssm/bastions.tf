data "aws_subnet" "private" {
  count = var.bastions_enabled ? 1 : 0

  id = var.private_subnet_id
}

# A security group to put the bastion instances in if enabled.
# The security group does not allow any ingress, just egress
# to reach the AWS Session Manager APIs. Note that with a VPC endpoint
# public egress would not be required.
resource "aws_security_group" "bastion_sg" {
  count = var.bastions_enabled ? 1 : 0

  name        = "sym-bastion-sg"
  description = "Security group for bastion instances"
  vpc_id      = data.aws_subnet.private[0].vpc_id


  egress {
    protocol         = "tcp"
    to_port          = 443
    from_port        = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}


module "frontend_bastion" {
  count = var.bastions_enabled ? 1 : 0

  source = "cloudposse/ec2-bastion-server/aws"

  ami                    = data.aws_ami.amazon_linux.id
  assign_eip_address     = false
  enabled                = var.bastions_enabled
  instance_type          = "t2.micro"
  name                   = "bastion-frontend"
  namespace              = "sym"
  security_group_enabled = false
  security_groups        = [aws_security_group.bastion_sg[0].id]
  ssm_enabled            = true
  subnets                = [data.aws_subnet.private[0].id]
  version                = "0.30.1"
  vpc_id                 = data.aws_subnet.private[0].vpc_id

  tags = merge(var.tags, { "Department" = "FrontEnd" })
}

module "backend_bastion" {
  count = var.bastions_enabled ? 1 : 0

  source = "cloudposse/ec2-bastion-server/aws"

  ami                    = data.aws_ami.amazon_linux.id
  assign_eip_address     = false
  enabled                = var.bastions_enabled
  instance_type          = "t2.micro"
  name                   = "bastion-backend"
  namespace              = "sym"
  security_group_enabled = false
  security_groups        = [aws_security_group.bastion_sg[0].id]
  ssm_enabled            = true
  subnets                = [data.aws_subnet.private[0].id]
  version                = "0.30.1"
  vpc_id                 = data.aws_subnet.private[0].vpc_id

  tags = merge(var.tags, { "Department" = "BackEnd" })
}
