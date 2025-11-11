terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create a VPC for the EKS Cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  # Create two availability zones
  azs = ["${var.aws_region}a", "${var.aws_region}b"] 

  # Define subnets for the VPC
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]  # For EKS Nodes
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # For Load Balancers

  # Configuration for internet access
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    KubernetesCluster = var.cluster_name
    Environment = "DevOps-Demo"
  }
}

# Create the EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.1.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group
  eks_managed_node_groups = {
    default = {
      name           = "default-node-group"
      instance_types = [var.instance_type]
      
      min_size     = 1
      max_size     = 3
      desired_size = var.node_desired_size
      
      subnet_ids = module.vpc.private_subnets
    }
  }
  
  tags = {
    Blueprint = "Observability-Stack"
    Environment = "DevOps-Demo"
  }

  access_entries = {
    gitlab_deployer = {
      # ARN of the IAM Role used by the CI/CD pipeline
      principal_arn     = "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/gitlab-ci-eks-deployer-role"
      kubernetes_groups = ["system:masters"] # Grants full administrative access
      type              = "STANDARD"
    }
  }
}