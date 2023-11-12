
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "A list of subnet IDs where cluster nodes will be provisioned"
  type        = list
  default     = []
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}
