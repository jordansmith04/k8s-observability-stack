#!/bin/bash

# Kubernetes Observability Stack Deployment Script to Minikube

# This script sets up a local Minikube environment and deploys all
# components of the k8s observability stack (Loki, Prometheus, Grafana,
# Promtail, and the Nginx microservice) using individual configurations.
#
# Usage: ./local_stack_development.sh [install|upgrade|delete]
# Example: ./local_stack_development.sh install

set -e

#  Configuration Variables 
NAMESPACE="k8s-obs-stack"

# Release names for individual Helm charts
LOKI_RELEASE_NAME="loki"
PROMETHEUS_RELEASE_NAME="prometheus"
NGINX_RELEASE_NAME="nginx-microservice"

ACTION=${1:-install} # Default action is install, Actions: [install|upgrade|delete]
ENV="minikube"

echo "================================================"
echo " Kubernetes Observability Stack Deployment (Local) "
echo "Action: $ACTION | Environment: $ENV | Namespace: $NAMESPACE"
echo "================================================"

#  Helper Functions 
setup_minikube() {
    echo "Checking Minikube status..."
    if ! command -v minikube &> /dev/null
    then
        echo "Minikube command not found. Please install Minikube."
        exit 1
    fi

    if ! minikube status &> /dev/null || [ "$(minikube status -f '{{.Host}}')" != "Running" ]; then
        echo "Minikube not running. Starting cluster..."
        # Ensure enough resources for the kube-prometheus-stack
        minikube start --driver=docker --memory=8192mb --cpus=4
    fi

    echo "Enabling required Minikube add-ons..."
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

#  Main Execution 

# Environment Setup
setup_minikube

# Namespace Preparation
wait_for_namespace

# Handle Deletion
if [ "$ACTION" == "delete" ]; then
    echo "Deleting all deployed Helm releases and resources in namespace '$NAMESPACE'..."
    helm uninstall "$LOKI_RELEASE_NAME" -n "$NAMESPACE" || true
    helm uninstall "$PROMETHEUS_RELEASE_NAME" -n "$NAMESPACE" || true
    helm uninstall "$NGINX_RELEASE_NAME" -n default || true # Nginx is in default namespace per CI

    echo "Deleting custom Promtail and Grafana resources..."
    kubectl delete -n "$NAMESPACE" -f loki/promtail-configmap.yaml || true
    kubectl delete -n "$NAMESPACE" -f loki/promtail-daemonset.yaml || true
    kubectl delete -n "$NAMESPACE" -f grafana/grafana-dashboard-configmap.yaml || true

    echo "Deletion complete."
    exit 0
fi

# Helm Repository Setup
echo "Checking and updating Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install or Upgrade Deployment
HELM_CMD="install"
if [ "$ACTION" == "upgrade" ]; then
    HELM_CMD="upgrade --reuse-values"
fi

if [ "$ACTION" == "install" ] || [ "$ACTION" == "upgrade" ]; then
    echo "Starting deployment sequence (Action: $ACTION)..."
    
    # Loki (Log Aggregation) 
    echo "Deploying Loki ($LOKI_RELEASE_NAME)..."
    helm $HELM_CMD "$LOKI_RELEASE_NAME" grafana/loki \
        --namespace "$NAMESPACE" \
        -f loki/values.yaml \
        --wait

    # Prometheus Stack (Metrics & Integrated Grafana) 
    echo "Deploying Prometheus Stack ($PROMETHEUS_RELEASE_NAME)..."
    helm $HELM_CMD "$PROMETHEUS_RELEASE_NAME" prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        -f prometheus/prometheus-values.yaml \
        --wait

    # Promtail (Log Collector) 
    echo "Applying custom Promtail manifests..."
    kubectl apply -n "$NAMESPACE" -f loki/promtail-configmap.yaml
    kubectl apply -n "$NAMESPACE" -f loki/promtail-daemonset.yaml

    # Grafana Dashboard ConfigMap 
    echo "Applying custom Grafana dashboard configmap..."
    kubectl apply -n "$NAMESPACE" -f grafana/grafana-dashboard-configmap.yaml

    # Nginx Microservice (App to observe) 
    echo "Deploying Nginx Microservice ($NGINX_RELEASE_NAME)..."
    # Note: Deploying the microservice to the default namespace for isolation from the observability stack
    helm $HELM_CMD "$NGINX_RELEASE_NAME" ./nginx \
        --namespace default \
        --wait
    
else
    echo "Invalid action specified. Use 'install', 'upgrade', or 'delete'."
    exit 1
fi

#  Post-Deployment Verification and Access Instructions 
echo " "
echo "--- Deployment Complete ---"

echo "Waiting for all major Pods to be ready..."
# Use a broad label selector for better coverage
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name -n "$NAMESPACE" --timeout=120s || true
echo "Basic Pod readiness check passed."

echo " "
echo "Your Kubernetes observability stack and microservice are deployed locally."
echo " "
echo "--- ACCESS INSTRUCTIONS ---"
echo "Minikube detected. Use 'minikube service' to access the UIs:"
echo " "
echo "   * Grafana Dashboard (Visualization):"
echo "     minikube service ${PROMETHEUS_RELEASE_NAME}-grafana -n ${NAMESPACE}"
echo " "
echo "   * Prometheus UI (Metrics):"
echo "     minikube service ${PROMETHEUS_RELEASE_NAME}-kube-p-prometheus -n ${NAMESPACE}"
echo " "
echo "   * Application Microservice (Nginx):"
echo "     minikube service ${NGINX_RELEASE_NAME} -n default"

echo " "
echo "Grafana Default Credentials: admin / prom-operator"
echo "---------------------------"