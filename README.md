# k8s-observability-stack
Kubernetes Monitoring Stack Deployment to EKS using Helm, Prometheus, Grafana, Loki and Gitlab CI/CD

This repository contains the full infrastructure-as-code (IaC) and deployment pipeline for provisioning an an Amazon EKS cluster and deploying a cloud-native observability stack (Prometheus, Grafana, and Loki) using Helm.

The entire process is automated through a GitLab CI/CD pipeline utilizing Terraform for infrastructure and Helm for application deployment.

## Infrastructure Overview

The pipeline executes Terraform code located in the terraform/ directory to provision the core infrastructure:

- Amazon EKS Cluster: Creates a fully managed Kubernetes cluster (${EKS_CLUSTER_NAME}).

- VPC and Networking: Provisions the necessary Virtual Private Cloud (VPC), subnets, and security groups to support the EKS cluster and allow external access.

- Worker Nodes: Sets up an Auto Scaling Group (ASG) of EC2 instances to act as the Kubernetes worker nodes.

- Once provisioned, the pipeline automatically generates a temporary Kubernetes configuration file (kubeconfig.yml) and uses it to deploy the application stack.

## Prerequisites and Setup

Before running the pipeline, you must ensure the following are configured in your GitLab project.

### 1. AWS Credentials (Required)

The pipeline requires access to your AWS account to provision resources. These credentials must be set as Secret Environment Variables in your GitLab project settings (Settings > CI/CD > Variables).

| Variable Key | Value Description | Type |
| ------- | -------- | -------|
| AWS_ACCESS_KEY_ID | Your AWS user access key ID | File or Variable |
| AWS_SECRET_ACCESS_KEY | Your AWS user secret access key | File or Variable | 

### 2. Custom Environment Variables (Optional)

The pipeline uses the following variables, defined in the .gitlab-ci.yml, for configuration. You can override these by setting them as variables in your GitLab project if you need different values.

| Variable Key | Default Value | Description |
| ------- | -------- | -------|
| AWS_REGION | us-east-1 | The AWS region where the EKS cluster will be deployed |
| EKS_CLUSTER_NAME | obs-demo-cluster | The name given to the EKS cluster | 
| TF_ROOT | terraform | Directory containing the Terraform code |
| HELM_CHART_PATH | helm | Path to the Helm chart within the repository | 
| K8S_NAMESPACE | k8s-obs-stack | Kubernetes namespace for the application deployment |

## Usage and Pipeline Stages

The pipeline is configured to automatically run on pushes to the repository, but the provision and deploy stages are restricted to the main branch for safety.

### 1. Validate Stage

- Purpose: Ensure the Terraform code is valid and generate an execution plan.

- Runs terraform init and terraform validate.

- Generates plan.tfplan artifact, which describes what changes will be made.

### 2. Provision Stage

- Purpose: Create or update the EKS infrastructure on AWS.

- Runs terraform apply using the plan created in the validate stage.

- After successful creation, it executes the AWS CLI command to generate and save the kubeconfig.yml file, which is crucial for the next stage.

- Runs on: main branch only.

### 3. Deploy Stage

- Purpose: Deploy the Observability Stack application onto the new EKS cluster.

- Uses the artifacted kubeconfig.yml to authenticate with the EKS cluster.

- Ensures the target Kubernetes namespace (k8s-obs-stack) exists.

- Executes helm upgrade --install to deploy the Helm chart found at helm/.

- Runs on: main branch only, after provision is successful.

### Running the Pipeline

1. Configure Secrets: Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in GitLab CI/CD variables.

2. Commit: Ensure your Terraform (terraform/) and Helm Chart (helm/) directories contain valid code.

3. Push: Push your changes to the main branch.

4. The pipeline will automatically execute, first creating the cluster, and then deploying the application, resulting in a fully provisioned and deployed environment.

### Cleanup and Destruction

- To remove the EKS cluster and all related AWS resources created by Terraform, you can manually run a destroy job.

- Temporarily add a new job to your .gitlab-ci.yml (or create a custom pipeline run) that executes the following script:
```
cd terraform
terraform init -backend-config="address=$TF_ADDRESS"
terraform destroy -auto-approve
```

Alternatively: Go into your terraform directory locally, run terraform init, and then terraform destroy. Ensure you use the same state backend configuration to target the remote state stored in GitLab.