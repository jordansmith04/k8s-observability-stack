# Nginx Microservice

This directory contains a complete, self-contained Helm chart for deploying the simple Nginx microservice. This microservice demonstrates a basic application that is then monitored by the observability stack.

## Directory Contents

| File Name | Description | 
| --------- | ----------- |
| chart.yaml | The metadata file defining the Helm chart's name, version, and API version. | 
| values.yaml | The default configuration values for the Nginx deployment, including image tag, replica count, resource requests, and service type (LoadBalancer). | 
| helm/deployment.yaml | The Kubernetes manifest to create the Deployment resource for the Nginx application. |
| helm/service.yaml | The Kubernetes manifest to create the Service resource (LoadBalancer) to expose the application. |

## Resources Created

- Deployment: Manages the Nginx application containers.

- Service: A LoadBalancer service that exposes the Nginx deployment externally, providing a public IP or DNS name.

## How to Deploy the Nginx Microservice

Since this is a local chart, you install it by referencing the directory path.

Install the Chart (from project root):
```
helm install nginx-web nginx \
  --namespace default \
  -f nginx/values.yaml
```

(Note: Using the default namespace here, but you can specify any namespace.)

Check External IP:
```
kubectl get svc nginx-web -n default
```
Note: The external IP/hostname will appear in the EXTERNAL-IP column.