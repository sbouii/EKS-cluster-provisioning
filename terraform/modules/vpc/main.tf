provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  name               = "unzer-case-study"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    project     = local.name
    terraform   = true
    environment = "prod"
    stack       = "vpc"
  }
}

module "vpc" {
  source  =  "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  name   = "${local.name}-vpc"
  cidr   = var.vpc_cidr
  azs    = local.availability_zones

  # three subnets in each availability zone
  public_subnets   = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true
  enable_nat_gateway           = true
  single_nat_gateway           = false
  one_nat_gateway_per_az       = true
  enable_dns_support           = true

  private_subnet_tags = {
   "kubernetes.io/role/internal-elb" = 1
  }

  public_subnet_tags = {
   "kubernetes.io/role/elb" = 1
  }

  tags = local.tags

}
