# Terraform EKS Infrastructure

This directory contains the necessary Terraform configuration files to provision the underlying AWS infrastructure (VPC, networking, and the Kubernetes cluster) for the observability stack and microservice deployments.

### Directory Contents

| File Name | Description |
| ------- | ------- |
| main.tf | The primary configuration file defining the AWS resources (VPC, Subnets, EKS Cluster, Node Groups). |
| variables.tf | Defines all input variables (like region, instance types, cluster name, etc.) used in main.tf. | 
| outputs.tf | Defines the values that are exported after provisioning (e.g., EKS Cluster endpoint, cluster name, Kubeconfig details). |

### Resources Created

- Networking: Virtual Private Cloud (VPC), public and private subnets, NAT Gateways, and Internet Gateway.

- Kubernetes Cluster: AWS Elastic Kubernetes Service (EKS) cluster control plane.

- Worker Nodes: Managed Node Groups for running Kubernetes workloads.

### How to Create Resources

These commands must be run from within the terraform/ directory.

Initialize Terraform:
```
terraform init
```

Review the Execution Plan:
```
terraform plan
```

Apply the Configuration (Provision Infrastructure):
```
terraform apply -auto-approve
```

Once complete, use the outputs to configure kubectl access to your new EKS cluster.