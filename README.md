# Kubernetes Observability Stack and EKS Provisioning

This project provides a comprehensive solution for provisioning an Amazon EKS cluster using Terraform and deploying a full Kubernetes Observability Stack (Loki, Prometheus, Grafana) using Helm charts and custom manifests. It also includes a sample Nginx microservice to generate metrics and logs for observation.

The pipeline is designed to be executed via GitLab CI/CD, but a dedicated script is provided for local development using Minikube.

## Project Overview & Architecture

The goal of this repository is to establish a complete monitoring and logging system for a Kubernetes workload.

### The Stack Includes:

| Component | Tool / Technology | Purpose | 
| -------- | ----------- | --------- |
| Infrastructure | Terraform| Provisioning of the AWS EKS Cluster and related networking. |
| Metrics| Prometheus (via kube-prometheus-stack)| Collects and stores time-series metric data. |
| Logging| Loki| Centralized log aggregation system. |
| Log Collector| Promtail| DaemonSet that ships logs from all nodes to Loki. |
| Visualization| Grafana| Dashboarding and visualization for both Prometheus (metrics) and Loki (logs). |
| Application| Nginx Microservice| A simple application deployed to generate metrics and logs for testing. |

### Repository Structure

| Directory/File | Description |
| -------- | ----------- |
| terraform/ | Contains all Terraform configuration (.tf files) required to provision the EKS cluster and IAM roles. | 
| loki/ | Custom Helm values.yaml for Loki, plus the YAML manifests for the Promtail DaemonSet and ConfigMap. | 
| prometheus/ | Custom Helm prometheus-values.yaml for the kube-prometheus-stack chart. | 
| grafana/ | Custom Grafana Dashboard ConfigMap used to load an initial dashboard configuration into the deployed Grafana instance. |
| nginx/ | A standalone Helm Chart for the sample Nginx microservice.
| .gitlab-ci.yml | The complete CI/CD pipeline definition for automated provisioning and deployment to AWS EKS. | 
local_stack_development.sh | A utility script for setting up the entire stack locally using Minikube. |

## Prerequisites

For CI/CD Deployment (GitLab & EKS)

- GitLab Repository: This project must be hosted on GitLab.

AWS Credentials:

Set the following as Protected CI/CD Variables in your GitLab project:

- AWS_ACCESS_KEY_ID

- AWS_SECRET_ACCESS_KEY

CI/CD Variables (Optional but Recommended):

- AWS_REGION: e.g., us-east-1 (Default)

- EKS_CLUSTER_NAME: e.g., obs-demo-cluster (Default)

For Local Development (Minikube)

- Docker: Required for the Minikube driver.

- Minikube: Latest version installed and configured.

- Helm: Latest version installed.

- Kubectl: Latest version installed.

- Bash: The local deployment script requires a standard Unix environment.

## Deployment Guide: CI/CD (EKS)

The .gitlab-ci.yml pipeline automates the entire process and runs only on the main branch.

### 1. Provisioning (terraform_provision)

This job uses Terraform to create the EKS cluster.

Action:

1. Initializes and validates Terraform configuration (in the terraform/ directory).

2. Applies the plan, provisioning the EKS cluster and worker nodes.

3. Generates a kubeconfig.yml file using the AWS CLI for the cluster, which is stored as a job artifact.

### 2. Deployment (helm_deploy)

This job uses the generated kubeconfig.yml to connect to the new EKS cluster and deploy the stack.

Action:

1. Sets the KUBECONFIG environment variable.

2. Creates the target namespace (k8s-obs-stack).

3. Installs Loki using its custom values.yaml.

4. Installs the Prometheus Stack (including built-in Grafana) using its custom prometheus-values.yaml.

5. Applies custom manifests for Promtail and the Grafana Dashboard ConfigMap.

6. Installs the Nginx Microservice chart into the default namespace.

## Local Development Guide (Minikube)

Use the provided local_stack_development.sh script to quickly launch and test the stack on your local machine.

### 1. Start Minikube

Ensure Minikube is running with adequate resources:
```
./local_stack_development.sh install
```

The script will automatically check for Minikube and start it if necessary, requesting 8GB of memory and 4 CPUs.

### 2. Install/Upgrade the Stack

The script uses individual Helm commands and kubectl apply to mirror the CI/CD environment.

| Action | Command | Description | 
| -------- | ----------- | ---------- |
| Install | ./local_stack_development.sh install | Sets up Minikube and performs a clean installation of all components. | 
| Upgrade | ./local_stack_development.sh upgrade| Upgrades existing Helm releases, reusing current values. |
| Delete| ./local_stack_development.sh delete| Uninstalls all Helm charts and deletes all custom resources. | 

### 3. Access the UIs

Once the deployment is complete, the script will provide the exact commands, but typically you can access the components via minikube service:

| Component| Access Command | Default Credentials |
| -------- | ----------- | ---------- |
| Grafana| minikube service prometheus-grafana -n k8s-obs-stack| admin / prom-operator | 
| Prometheus| minikube service prometheus-kube-p-prometheus -n k8s-obs-stack| N/A | 
| Nginx App| minikube service nginx-microservice -n default| N/A |