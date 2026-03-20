## Description:
 Infrastructure as code stack to provision EKS Cluster.

## Dependencies:
- kubernetes >= 1.3
- aws access configured

## Usage:
```
cd terraform/

terraform init

terraform plan

terraform apply
```

## Infrastructure Architecture:

Infrastructure as code contains 4 modules:

   vpc: to set up VPC with single region multi-AZ architecture.
   
   eks: to deploy EKS cluster in the VPC.
   
   irsa: to create necessary IAM roles with the required permissions.  
   
   kubernetes-provision: to deploy kubernetes resources in EKS cluster


<div align="center">
    <img src="EKS Cluster Architecture.png" width="400px"</img> 
</div>


### Scalability/Availability and Security measures:

For EKS nodes scaling, cluster-autoscaler is used to scale-out or scale-in number of nodes within a node group based on the load.

The subnets are spread across the 3 availability zones of AWS region in case of AZ outage or for disaster recovery strategies.

Instead of deploying one single NAT Gateway to route traffic, 3 NAT Gateways are provisioned, one in each availability zone to ensure zone-independent architecture.

For avoiding resources throttling at the nodes level, we set resources limits for the pods.

Each type of pods are scheduled on dedicated node group using taints and tolerations:

Redis pods are scheduled on memory optimised instances while the rest of the pods are scheduled on general-purpose instances.

For encrypting k8s nodes EBS volumes instead of using default kms keys, dedicated Customer KMS key is created.

## Redis Cluster Architecture:  

Redis Cluster is deployed on EKS cluster as Helm chart through Terraform Helm provider.

<div align="center">
    <img src="Redis Cluster Architecture.png" width="400px"</img> 
</div>

The cluster is deployed as statefulSet since Redis is considered as stateful application that requires each pod to have its own persistent storage.

There is two different architectures to deploy Redis on top of Kubernetes Cluster:

- Redis with cluster mode enabled:

It's recommended when you have one big dataset and you need multiple write endpoints and the ability to scale horizontally, but it doesn't support multiple
databases.

The data is spread across different shards, each shard should exist in a separate kubernetes node to guarantee the high availability and in order to
avoid any data loss, there should be at least one replica per master. In case the master node goes down, there will be failover to the replica node, although
the data slots stored by the crashed master will be unavailable until failover is done.

Also when enabling the replication, you have separate write endpoint for write operations and read endpoint for read operations. This can help in reducing
the load on the master node.

Although the replication is asynchronous, so it doesn't guarantee strong consistency for read requests (in case a master node crashes before propagating the
writes to the replica).

The minimal Redis cluster that works as expected requires to contain at least three master nodes in the cluster and at least one slave for each master 
(to allow minimal fail-over mechanism).

Also with cluster mode enabled, you have the possibility to scale in or out easily by adding or removing shards.

- Redis with cluster mode disabled:

It's recommended when you want to have multiple databases and you don't need more than one single write endpoint.

When the cluster mode is disabled, you have one single shard which contains one master node and the replicas (if the replication is enabled).

In both architectures, it's recommended to enable data persistence:

Since Redis is in-memory store, it means if the master pods restarted or crashed, the data will get lost.

By default the chart will create hostPath persistent volume when you don't specify a storage class. But it's recommended to configure your own storage class in order to dynamically provision persistent volumes for Redis pods. In the case study, we used AWS-EBS as the storage class for PVS provisioning.

Redis uses RDB(Redis Database) and AOF (Append Only File) mechanisms to persist data to disk space:

RDB persistence performs point-in-time snapshots of your dataset at specified intervals.

AOF persistence logs every write operation received by the server.

## CI/CD solution to release updates to Redis Cluster:

The helm chart offers the PodDistributionBudget feature which allows to rollout deployment with zero downtime.
You specify maximum unavailable pods and/or the minimum available ones during deployment restart/rollout. This guarantees
that there will be always enough pods available during the update process.

## Observability:

We can use prometheus operator to scrape metrics from Redis Pods. The chart offers running an exporter called redis-exporter as as a side car to Redis Pod.
More details about metrics scraping configuration : https://github.com/bitnami/charts/tree/main/bitnami/redis-cluster#metrics-sidecar-parameters
