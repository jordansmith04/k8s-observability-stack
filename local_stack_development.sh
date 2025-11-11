#!/bin/bash

# Kubernetes Observability Stack Deployment Script

# This script sets up a local Minikube environment
# and deploys the k8s-observability-stack Helm chart, including Prometheus, 
# Grafana, Loki, and the sample microservice.
#
# Usage: ./deploy.sh [install|upgrade|delete]
# Example: ./deploy.sh install


set -e
HELM_RELEASE_NAME="k8s-observability-demo"
NAMESPACE="k8s-obs-stack"
CHART_PATH="./helm"

ACTION=${1:-install} # Default action is install, Actions: [install|upgrade|delete]
ENV="minikube"        

echo " Kubernetes Observability Stack Deployment "
echo "Action: $ACTION | Environment: $ENV | Release: $HELM_RELEASE_NAME | Namespace: $NAMESPACE"

# Helper Functions
setup_minikube() {
    echo "Checking Minikube status..."
    if ! command -v minikube &> /dev/null
    then
        echo "Minikube command not found. Please install Minikube."
        exit 1
    fi

    if ! minikube status &> /dev/null || [ "$(minikube status -f '{{.Host}}')" != "Running" ]; then
        echo "Minikube not running. Starting cluster..."
        minikube start --driver=docker --memory=8192mb --cpus=4
    fi

    echo "\Enabling required Minikube add-ons..."
    # Metrics server must be installed for Prometheus to scrape node/pod metrics
    minikube addons enable metrics-server || true
    echo "Minikube setup complete."
}

wait_for_namespace() {
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
    echo "Namespace $NAMESPACE is ready."
}

# Environment Setup
if [ "$ENV" == "minikube" ]; then
    setup_minikube
fi

# Namespace Preparation
wait_for_namespace

# Handle Deletion
if [ "$ACTION" == "delete" ]; then
    echo "Deleting Helm release '$HELM_RELEASE_NAME'..."
    helm uninstall "$HELM_RELEASE_NAME" -n "$NAMESPACE"
    echo "Deletion complete. You may need to manually delete the namespace and persistent volumes."
    exit 0
fi

# Helm Repository Setup
echo "Checking and updating Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Dependency Update
echo "Fetching Helm chart dependencies..."
helm dependency update "$CHART_PATH"

# Install or Upgrade Deployment
if [ "$ACTION" == "install" ]; then
    echo "Installing Helm release '$HELM_RELEASE_NAME'..."
    helm install "$HELM_RELEASE_NAME" "$CHART_PATH" --namespace "$NAMESPACE" --create-namespace
elif [ "$ACTION" == "upgrade" ]; then
    echo "Upgrading Helm release '$HELM_RELEASE_NAME'..."
    helm upgrade "$HELM_RELEASE_NAME" "$CHART_PATH" --namespace "$NAMESPACE" --reuse-values
else
    echo "Invalid action specified. Use 'install', 'upgrade', or 'delete'."
    exit 1
fi

# Post-Deployment Verification and Access Instructions
echo "--- Deployment Complete ---"

echo "Waiting for all Pods to be ready in namespace $NAMESPACE (up to 120 seconds)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance="$HELM_RELEASE_NAME" -n "$NAMESPACE" --timeout=120s || true
echo "Basic Pod readiness check passed."

echo " "
echo "Your Kubernetes observability stack and microservice are deployed."
echo " "
echo "--- ACCESS INSTRUCTIONS ---"
echo "Minikube detected. Use 'minikube service' to access services:"
echo " "
echo "   * Grafana Dashboard (Visualization):"
echo "     minikube service ${HELM_RELEASE_NAME}-kube-prometheus-stack-grafana -n ${NAMESPACE}"
echo " "
echo "   * Prometheus UI (Metrics):"
echo "     minikube service ${HELM_RELEASE_NAME}-kube-prometheus-stack-prometheus -n ${NAMESPACE}"
echo " "
echo "   * Application Microservice:"
echo "     minikube service ${HELM_RELEASE_NAME} -n ${NAMESPACE}"

echo " "
echo "Grafana Default Credentials: admin / prom-operator"

echo " "
echo "---------------------------"