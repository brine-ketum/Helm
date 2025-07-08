# My App Helm Chart

This is a production-grade Helm chart for deploying containerized applications to Kubernetes.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.10+
- PV provisioner support in the underlying infrastructure (if using persistence)
- Ingress controller (NGINX recommended)
- cert-manager (for TLS certificates)
- Prometheus Operator (if using ServiceMonitor)

## Installation

### Add Helm repository (if hosted)
```bash
helm repo add myrepo https://charts.example.com
helm repo update
```

### Install from local directory

1. **Basic installation with default values:**
```bash
helm install my-app ./my-app-chart \
  --namespace my-app \
  --create-namespace
```

2. **Production installation:**
```bash
helm install my-app ./my-app-chart \
  --namespace my-app-prod \
  --create-namespace \
  -f ./my-app-chart/values-prod.yaml
```

3. **Installation with custom values:**
```bash
helm install my-app ./my-app-chart \
  --namespace my-app \
  --create-namespace \
  --set image.repository=us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-app \
  --set image.tag=v1.2.3 \
  --set ingress.hosts[0].host=my-app.example.com
```

## Upgrading

```bash
helm upgrade my-app ./my-app-chart \
  --namespace my-app \
  -f ./my-app-chart/values-prod.yaml
```

## Uninstallation

```bash
helm uninstall my-app --namespace my-app
```

## Configuration

See `values.yaml` for the full list of configurable parameters.

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | `1.25.3-alpine` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `ingress.enabled` | Enable ingress | `true` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

## Testing

```bash
# Lint the chart
helm lint ./my-app-chart

# Dry run installation
helm install my-app ./my-app-chart --dry-run --debug

# Run tests
helm test my-app --namespace my-app
```

## Monitoring

This chart includes:
- Prometheus ServiceMonitor for metrics collection
- Resource limits and requests for proper scheduling
- Health checks (liveness, readiness, startup probes)
- HPA for automatic scaling

## Security Features

- Pod Security Context with non-root user
- Read-only root filesystem
- Network policies
- RBAC with minimal permissions
- Security headers in Ingress

## Customizing for Your Application

1. Update `image.repository` and `image.tag` in values.yaml
2. Modify `configMap.data` for your application config
3. Update health check paths in `livenessProbe` and `readinessProbe`
4. Adjust `resources` based on your application needs
5. Configure environment variables in `env` section

## Directory Structure

```
my-app-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml            # Default values
├── values-prod.yaml       # Production overrides
├── templates/             # Kubernetes templates
│   ├── deployment.yaml    # Main application deployment
│   ├── service.yaml       # Service definition
│   ├── ingress.yaml       # Ingress rules
│   ├── hpa.yaml          # Horizontal Pod Autoscaler
│   └── ...               # Other resources
└── README.md             # This file
```

## Support

For issues and feature requests, please open an issue in the repository.
