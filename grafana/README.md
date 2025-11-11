# Grafana Dashboards and Customization

This directory contains configuration files primarily used to add custom dashboards or fine-tune the Grafana instance that is deployed as part of the kube-prometheus-stack.

| File Name | Description | 
| --------- | ----------- |
| values.yaml | Custom values file for Grafana. Note: Since Grafana is typically deployed via the Prometheus stack, this file may only be needed if deploying Grafana separately or for highly specific customizations not handled by prometheus/prometheus-values.yaml. |
| grafana-dashboard-configmap.yaml | A ConfigMap containing a custom JSON dashboard definition. This is used to automatically load new dashboards into the deployed Grafana instance. | 

## Resources Created

- ConfigMap: A Kubernetes ConfigMap that Grafana uses to discover and load new dashboards on startup/reload.
- Grafana Deployment: The main Grafana server and its persistent volume.
- Service: The Kubernetes Service exposing Grafana (accessible via LoadBalancer or NodePort).

## How to Deploy Grafana and Custom Dashboards

These commands assume you are running from the project root directory and the EKS cluster is ready.

1. Install Grafana Server:
```
helm install grafana grafana/grafana \
  --namespace k8s-obs-stack \
  -f grafana/values.yaml
```

2. Deploy Custom Dashboard ConfigMap:
```
kubectl apply --namespace k8s-obs-stack -f grafana/grafana-dashboard-configmap.yaml
```

Grafana is configured to automatically pick up any dashboard ConfigMaps in its namespace, making the new dashboard immediately available in the UI.

3. Retrieve Grafana Access Details:
```
kubectl get svc grafana -n k8s-obs-stack 
# Find the external IP
# Find the admin password (requires chart configuration to be default or set in values.yaml)
# kubectl get secret --namespace k8s-obs-stack grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```


The Grafana server is already deployed when you install the Prometheus stack. You simply need to apply the custom ConfigMap to the correct namespace for Grafana to pick it up.

4. Apply Dashboard ConfigMap (from project root):
```
kubectl apply --namespace k8s-obs-stack -f grafana/grafana-dashboard-configmap.yaml
```

This action will automatically make the dashboard available in the Grafana UI.