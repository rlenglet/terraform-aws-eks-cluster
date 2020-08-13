variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

# This cluster role must already exist and be attached the
# AmazonEKSClusterPolicy, cf.
# https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
variable "cluster_role_name" {
  description = "The name of the role given to the EKS cluster"
  type        = string
}

# This worker node role must already exist and be attached the
# AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, and
# AmazonEC2ContainerRegistryReadOnly, cf.
# https://docs.aws.amazon.com/eks/latest/userguide/worker_node_IAM_role.html
variable "worker_node_role_name" {
  description = "The name of the role given to the EKS worker nodes"
  type        = string
}

# A dedicated VPC is created for the cluster.
# An IGW is created in the VPC, since EKS node group nodes must have
# public access to register with the Kubernetes API server.
variable "vpc_cidr_block" {
  description = "The IP CIDR prefix of the VPC created to run the EKS cluster"
  type        = string
}

# For each availability zone, one public subnet and one private subnet
# are created, each with a CIDR block that is contained in
# vpc_cidr_block and that has no overlap with any other subnet within
# the VPC.
# A single node group named "Default" is created for the cluster.
# The Default node group's nodes are created in the private subnets.
# Each private subnet has a default route to a NAT gateway created in
# the public subnet in the same zone.
variable "availability_zones" {
  description = "The map of availability zone names to their configurations"
  type = map(object({
    public_cidr_block  = string
    private_cidr_block = string
  }))
}

# The minimum number of nodes should be the number of availability
# zones.
variable "node_group_min_size" {
  description = "The minimum number of nodes in the Default node group"
  type        = number
  default     = 1
}

variable "node_group_desired_size" {
  description = "The desired number of nodes in the Default node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "The maximum number of nodes in the Default node group"
  type        = number
}

variable "node_group_instance_types" {
  description = "The instance types of nodes in the Default node group"
  type        = list(string)
  default     = ["t3.medium"]
}
