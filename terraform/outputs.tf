# --- EKS Outputs ---
output "kubeconfig" {
  description = "The generated kubeconfig file content for the cluster."
  value       = module.eks.kubeconfig
  sensitive   = true # Do not show in standard output
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_id
}

# --- VPC Outputs ---
output "vpc_id" {
  description = "The ID of the VPC created for the EKS cluster."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets."
  value       = module.vpc.public_subnets
}