
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "eks_cluster" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  default     = ""
}
