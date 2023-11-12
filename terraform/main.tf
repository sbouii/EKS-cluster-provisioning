module "vpc" {
  source = "./modules/vpc"

}

module "eks" {
  source     = "./modules/eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_groups = {
    infra = {
      labels = {
        "workload" = "infra"
        "scaling"  = "true"
      }
    }
    redis = {
      instances_types = ["m5.large"]
      min_size        = 3
      max_size        = 6
      desired_size    = 3
      taints = [{
        "key" : "dedicated",
        "value" : "redis",
        "effect" : "NO_SCHEDULE"
      }]
      labels = {
        "workload" = "redis"
        "scaling"  = "true"
      }
    }
  }

}

module "irsa" {
  source            = "./modules/irsa"
  oidc_provider_arn = module.eks.oidc_provider_arn
  eks_cluster       = module.eks.cluster_name
}

module "kubernetes-provision" {
  source                             = "./modules/kubernetes-provision"
  eks_cluster                        = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

}
