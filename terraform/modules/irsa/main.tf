provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  name   = "unzer-case-study"
  tags = {
    project     = local.name
    terraform   = true
    environment = "prod"
    stack       = "irsa"
  }
}

module "cluster_autoscaler_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"
  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.eks_cluster]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = local.tags
}
