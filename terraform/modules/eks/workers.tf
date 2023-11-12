locals {
  eks_managed_node_group_defaults = {
        name            = "${local.name}-worker-group"
        use_name_prefix = true
        instance_types  = ["t3.large"]
        min_size        = 1
        max_size        = 3
        desired_size    = 2
        ebs_optimized  = true
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              encrypted = true
              kms_key_id = module.ebs_kms_key.key_arn
              delete_on_termination = true
            }
         }
        }
        tags = merge(local.tags ,{
          "k8s.io/cluster/${local.name}-eks"   = "owned"
          "k8s.io/cluster-autoscaler/enabled"  = "true"
          "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/lifecycle" = "true"
          propagate_at_launch = true
        })
    }
}
