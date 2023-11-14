# Description:
 Terraform stack to run .

# Dependencies:
- terraform >= 1.0
- aws access configured

#Usage:
'''
cd terraform/
terraform init
terraform plan
terraform apply
'''

#Infrastructure Architecture:

Terraform code contains 4 modules:
   vpc:  TO set up VPC with single region multi-AZs architecture.
   eks:  TO deploy EKS cluster in the VPC.
   irsa: TO create necessary IAM roles with the required permissions.  
   kubernetes-provision: TO deploy kubernetes resources in EKS cluster

Scalability/Availability and Security measures:

For EKS nodes scaling, cluster-autoscaler is used to scale-out or scale-in number of nodes within a node group based on  the load.

The subnets are spread across the 3 availability zones of AWS region in case of AZ outage or for disaster recovery strategies.

Instead of deploying one single NAT Gateway to route traffic, 3 NAT Gateways are provisioned, one in each availability zone.  

For avoiding resources throttling at the nodes level, we set resources limits for the pods.

Each type of pods are scheduled on dedicated node group using taints and tolerations:

Redis pods are scheduled on memory optimised instances while the rest of the pods are scheduled on general-purpose instances.

For encrypting k8s nodes EBS volumes instead of using default kms keys, dedicated Customer KMS key is created.

#Redis Cluster Architecture:  

Redis Cluster is deployed on EKS cluster as Helm chart through Terraform Helm provider.

The cluster is deployed as statefulSet since Redis is considered as stateful application that requires each pod to have its own persistent storage.

There is two different architectures to deploy Redis on top of Kubernetes Cluster:

- Redis with cluster mode enabled:

It's recommended when you have one big dataset and you need multiple write endpoints and the ability to scale horizontally, but it doesn't support multiple
databases.

The data is spread across different shards, each shard should exist in a separate kubernetes node to guarantee the high availability and in order to
avoid any data loss, there should be at least one replica per master.In case the master node goes down, there will be failover to the replica node.

Also when enabling the replication, you have separate write endpoint for write operations and read endpoint for read operations. This can help in reducing
the load on the master node.

Although the replication is asynchronous, so it doesn't guarantee strong consistency for read requests (in case a master node crashes before propagating the
writes to the replica)

The minimal Redis cluster that works as expected requires to contain at least three master nodes in the cluster and at least one slave for each master.
(to allow minimal fail-over mechanism).

Also with cluster mode enabled, you have the possibility to scale in or out easily by adding or removing shards.

- Redis with cluster mode disabled:

It's recommended when you want to have multiple databases and you don't need more than one single write endpoint.

When the cluster mode is disabled, you have one single shard which contains one master node and the replicas (if the replication is enabled).

In both architecture, it's recommended to enable data persistence:
