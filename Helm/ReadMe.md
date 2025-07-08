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


# Customizing the Helm Chart for Any Application

## Quick Customization Guide

### 1. For a Node.js Application

```yaml
# values.yaml
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-node-app
  tag: "v1.0.0"
  
service:
  port: 80
  targetPort: 3000  # Node.js default port

env:
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3000"

# Update deployment.yaml container port
containerPort: 3000
```

### 2. For a Python Flask/Django Application

```yaml
# values.yaml
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-python-app
  tag: "v1.0.0"
  
service:
  port: 80
  targetPort: 8000  # Python default port

env:
  - name: PYTHONUNBUFFERED
    value: "1"
  - name: DJANGO_SETTINGS_MODULE
    value: "myapp.settings.production"
  - name: PORT
    value: "8000"

# Add gunicorn command in deployment.yaml
command: ["gunicorn"]
args: ["--bind", "0.0.0.0:8000", "--workers", "4", "myapp.wsgi:application"]
```

### 3. For a Java Spring Boot Application

```yaml
# values.yaml
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-java-app
  tag: "v1.0.0"
  
service:
  port: 80
  targetPort: 8080  # Spring Boot default

env:
  - name: JAVA_OPTS
    value: "-Xmx512m -Xms256m"
  - name: SPRING_PROFILES_ACTIVE
    value: "production"

resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Update health checks for Spring Boot actuator
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
```

### 4. For a Go Application

```yaml
# values.yaml
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-go-app
  tag: "v1.0.0"
  
service:
  port: 80
  targetPort: 8080

env:
  - name: GIN_MODE
    value: "release"
  - name: PORT
    value: "8080"

# Go apps are typically lightweight
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### 5. For a React/Vue/Angular SPA with API

```yaml
# For frontend (served by nginx)
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-frontend
  tag: "v1.0.0"

# Mount custom nginx config
configMap:
  data:
    nginx.conf: |
      server {
        listen 8080;
        root /usr/share/nginx/html;
        
        location / {
          try_files $uri /index.html;
        }
        
        location /api {
          proxy_pass http://backend-service:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }
      }

# For backend API (separate deployment)
backend:
  image:
    repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-api
    tag: "v1.0.0"
```

## Common Customizations

### 1. Adding Database Connections

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: url
```

### 2. Adding Redis/Cache

```yaml
env:
  - name: REDIS_URL
    value: "redis://redis-service:6379"
```

### 3. Adding File Storage

```yaml
volumes:
  - name: uploads
    persistentVolumeClaim:
      claimName: app-uploads

volumeMounts:
  - name: uploads
    mountPath: /app/uploads
```

### 4. Adding Cron Jobs

Create a separate template `cronjob.yaml`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ .Release.Name }}-cron
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cron
            image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
            command: ["./run-cleanup.sh"]
```

### 5. Multi-Container Pods (Sidecar Pattern)

```yaml
sidecarContainers:
  - name: cloudsql-proxy
    image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.0
    args:
      - "--port=5432"
      - "poc-project-463913:us-west2:myinstance"
```

## Step-by-Step Customization Process

1. **Update Image Settings**
   ```bash
   # In values.yaml
   image:
     repository: <your-registry>/<your-app>
     tag: <your-version>
   ```

2. **Configure Ports**
   - Update `service.targetPort` to match your app's port
   - Update `containerPort` in deployment.yaml

3. **Set Environment Variables**
   - Add all required env vars to `env:` section
   - Use secrets for sensitive data

4. **Configure Health Checks**
   - Update probe paths to match your app's health endpoints
   - Adjust timing based on startup time

5. **Set Resource Requirements**
   - Monitor actual usage and set appropriate requests/limits
   - Start conservative and increase as needed

6. **Configure Persistence (if needed)**
   - Enable persistence section
   - Create PVC templates

7. **Add Dependencies**
   - Database connections
   - Cache services
   - Message queues

## Deployment Commands for Custom App

```bash
# 1. Build and push your image
docker build -t my-app:v1.0.0 .
docker tag my-app:v1.0.0 us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-app:v1.0.0
docker push us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-app:v1.0.0

# 2. Update values.yaml with your image

# 3. Deploy
helm install my-app ./my-app-chart \
  --namespace production \
  --create-namespace \
  --set image.tag=v1.0.0

# 4. Verify
kubectl get pods -n production
kubectl logs -f deployment/my-app -n production
```