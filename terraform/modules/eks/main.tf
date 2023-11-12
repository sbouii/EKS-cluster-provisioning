provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name   = "unzer-case-study"
  tags = {
    project     = local.name
    terraform   = true
    environment = "prod"
    stack       = "eks"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.17.2"
  cluster_name    = "${local.name}-eks"
  cluster_version = "1.28"
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  cluster_endpoint_public_access   = true
  cluster_endpoint_private_access  = true

  eks_managed_node_group_defaults = local.eks_managed_node_group_defaults

  eks_managed_node_groups = var.eks_managed_node_groups

  enable_irsa    = true
  create_iam_role = true
  iam_role_name = "${local.name}-iam-role"
  iam_role_use_name_prefix = false

  cluster_tags   = local.tags
}

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.5"
  description = "Customer KMS key for nodes EBS volumes encryption"

  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    module.eks.cluster_iam_role_arn,
  ]

  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}
