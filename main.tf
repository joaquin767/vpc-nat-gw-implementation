provider "aws" {
  region = "us-east-1"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-1"
  cidr = "10.98.0.0/16"

  azs             = ["us-east-1b"]
  private_subnets = ["10.98.1.0/24"]
  public_subnets = ["10.98.2.0/24"]
  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "joaquin-test.pub"
  public_key = file("${path.module}/joaquin-test.pub")
}

module "sg_public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_public"
  description = "Security group public"
  vpc_id      =  module.vpc.vpc_id

  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "sg_private" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_private"
  description = "Security group private"
  vpc_id      =  module.vpc.vpc_id

  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh port"
      cidr_blocks = "10.98.0.0/16"
    }
  ]
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  name = "public-ec2"

  ami                    = "ami-01cc34ab2709337aa"
  instance_type          = "t2.micro"
  key_name               = module.key_pair.key_pair_key_name
  monitoring             = true
  vpc_security_group_ids = [module.sg_public.security_group_id]
  subnet_ids              = module.vpc.public_subnets
  associate_public_ip_address = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "ec2_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  name = "private-ec2"

  ami                    = "ami-01cc34ab2709337aa"
  instance_type          = "t2.micro"
  key_name               = module.key_pair.key_pair_key_name
  monitoring             = true
  vpc_security_group_ids = [module.sg_private.security_group_id]
  subnet_ids              = module.vpc.private_subnets
  associate_public_ip_address = false
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


