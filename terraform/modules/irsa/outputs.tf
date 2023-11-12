
output "iam_role_arn_cluster_autoscaler_irsa_role" {
  description = "ARN of IAM role"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
}
