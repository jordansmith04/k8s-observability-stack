# Helm Deployment Scripts

This directory serves as the primary deployment entry point for the Kubernetes applications (Loki, Prometheus, Grafana, and Nginx). It centralizes the Helm installation commands, referencing the custom configuration files from the sibling directories.

## Directory Contents

This directory typically contains helper scripts or documentation for the deployment process, ensuring all charts are installed in the correct order using their specific configuration files.

## Resources Created

This directory orchestrates the creation of resources defined in the other directories:

- Observability Stack: Loki, Promtail (Log Collection), Prometheus, Alertmanager, and Grafana (Metrics & Logging UI).

- Microservice: The Nginx web application (Deployment and LoadBalancer Service).

## How to Deploy the Observability Stack (EKS Cluster must be running)

Assuming you are in the project root directory, follow these steps to deploy the stack into the k8s-obs-stack namespace.

### 1. Add Chart Repositories:
```
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo add grafana [https://grafana.github.io/helm-charts](https://grafana.github.io/helm-charts)
helm repo update
```

### 2. Install Loki (Log Aggregation):
```
helm install loki grafana/loki \
  --namespace k8s-obs-stack --create-namespace \
  -f ../loki/values.yaml
```

If you are using the custom Promtail DaemonSet/ConfigMap (in ../loki/), apply them separately using:
```
kubectl apply -f ../loki/promtail-configmap.yaml,../loki/promtail-daemonset.yaml
```

### 3. Install Prometheus Stack (Metrics & Integrated Grafana):
```
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace k8s-obs-stack \
  -f ../prometheus/prometheus-values.yaml
```

### 4. Apply Custom Grafana Dashboards:
```
kubectl apply -f ../grafana/grafana-dashboard-configmap.yaml \
  --namespace k8s-obs-stack
```