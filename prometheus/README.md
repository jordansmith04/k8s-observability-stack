# Prometheus Metrics Configuration

This directory holds the custom values file for configuring the kube-prometheus-stack Helm chart. This chart installs Prometheus, Alertmanager, and Grafana, providing full cluster monitoring.

## Directory Contents
| File Name | Description | 
| --------- | ----------- |
| prometheus-values.yaml | Custom configuration for the kube-prometheus-stack chart. It defines persistence, resource limits, and crucially, pre-configures Grafana to use the Loki service as a data source. |

## Resources Created via Helm Chart

- Prometheus Server: Time-series database and metric collection engine (with persistent storage).

- Alertmanager: Handles alerting and notification routing.

- Grafana: Visualization UI (configured to use Loki and Prometheus).

- Exporters: Node Exporter and Kube State Metrics for cluster-wide metric collection.

- Service Monitors: Kubernetes custom resources that tell Prometheus what to scrape.

## How to Deploy

The deployment command is typically executed from the project root or the helm/ directory (see ../helm/README.md).
```
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace k8s-obs-stack \
  -f prometheus/prometheus-values.yaml 
```
Note: Assuming execution from the root directory

The file path used in the deployment script must be correct, for example: helm install prometheus ... -f ../prometheus/prometheus-values.yaml.