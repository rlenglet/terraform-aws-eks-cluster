output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC associated with the EKS cluster"
}

output "endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "The Kubernetes API endpoint of the EKS cluster"
}

output "kubeconfig-certificate-authority-data" {
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  description = "The base64-encoded certificate data required to communicate with the EKS cluster"
}
