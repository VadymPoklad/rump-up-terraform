provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc" 
  region = var.aws_region
}

module "ec2" {
  source = "./modules/ec2" 
  region = var.aws_region
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
}

module "api" {
  source = "./modules/api" 
  region = var.aws_region
}

