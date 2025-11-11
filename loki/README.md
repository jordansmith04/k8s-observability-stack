# Loki Log Aggregation

This directory contains the configuration and manifests necessary to deploy the Loki log aggregation system and its log collection agent, Promtail.

## Directory Contents

| File Name | Description | 
| --------- | ----------- |
| values.yaml | Custom values for the loki Helm chart, defining persistence, service details, and resource allocation for the Loki server. |
| promtail-configmap.yaml | Custom Manifest: Defines the configuration for the Promtail agent, including where to find logs and how to send them to the Loki service. | 
| promtail-daemonset.yaml | Custom Manifest: Deploys Promtail as a DaemonSet to ensure a log collection agent runs on every node in the EKS cluster. |

## Resources Created

- Loki Deployment: The log aggregation server (receives and indexes logs).

- Promtail DaemonSet: Deploys the log collector to every node to stream logs into Loki.

- Service: Exposes the Loki server (usually on port 3100) internally to Promtail and Grafana.

## How to Deploy

The Loki server is installed via Helm using the values file, and the custom Promtail resources are applied directly via kubectl.

Install Loki Server (from project root):
```
helm install loki grafana/loki \
  --namespace k8s-obs-stack \
  -f loki/values.yaml
```

Deploy Custom Promtail Agent (from project root):
```
kubectl apply --namespace k8s-obs-stack -f loki/promtail-configmap.yaml
kubectl apply --namespace k8s-obs-stack -f loki/promtail-daemonset.yaml
```