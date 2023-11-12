locals {
  name = "redis"
  tags = {
    project     = local.name
    terraform   = true
    environment = "prod"
    stack       = "eks"
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster]
      command     = "aws"
    }
  }
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.name
  }
}

resource "kubernetes_storage_class" "storage-class" {
  metadata {
    name = "redis"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Retain"
  parameters = {
    type   = "gp2"
    fsType = "ext4"
  }
}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  values = [
    templatefile("${path.module}/cluster-autoscaler-values.yaml", {
      account_id  = data.aws_caller_identity.current.account_id,
      eks_cluster = "${var.eks_cluster}"
      region      = "${var.region}"
    })
  ]
}

resource "helm_release" "redis" {
  name       = local.name
  namespace  = local.name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis-cluster"
  values     = [
    "${file("${path.module}/redis-values.yaml")}"
  ]
}
