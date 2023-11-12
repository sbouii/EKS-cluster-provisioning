
output "cluster-autoscaler_release_metadata" {
  description = "cluster-autoscaler release metadata"
  value       = "${helm_release.cluster-autoscaler.metadata}"
}

output "redis_release_metadata" {
  description = "redis release metadata"
  value       = "${helm_release.redis.metadata}"
}
