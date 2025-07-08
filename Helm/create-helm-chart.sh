#!/bin/bash

# Complete Helm Chart Creation Script for Mac
# This script creates all directories and files with content

echo "🚀 Creating Production-Grade Helm Chart..."

# Create main directory
mkdir -p my-app-chart
cd my-app-chart

# Create subdirectories
mkdir -p templates/tests

echo "📁 Creating directory structure..."

# Create Chart.yaml
cat > Chart.yaml << 'EOF'
apiVersion: v2
name: my-app-chart
description: A production-grade Helm chart for Kubernetes applications
type: application
version: 1.0.0
appVersion: "1.0.0"
home: https://github.com/yourusername/my-app-chart
sources:
  - https://github.com/yourusername/my-app
maintainers:
  - name: Your Name
    email: your.email@example.com
    url: https://github.com/yourusername
keywords:
  - nginx
  - web
  - application
icon: https://example.com/icon.png
annotations:
  category: WebApplication
  licenses: Apache-2.0
EOF

echo "✅ Created Chart.yaml"

# Create values.yaml
cat > values.yaml << 'EOF'
# Default values for my-app-chart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

# Global settings
global:
  # Image pull secrets for private registries
  imagePullSecrets: []
  # - name: regcred
  
# Namespace configuration
namespace:
  create: true
  name: my-app
  labels: {}
  annotations: {}

# Basic application settings
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25.3-alpine"
  # For private registries
  # repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-app

# Image pull secrets (if using private registry)
imagePullSecrets: []
# - name: docker-registry-secret

nameOverride: ""
fullnameOverride: ""

# Service Account
serviceAccount:
  create: true
  annotations: {}
  name: ""
  # For workload identity
  # annotations:
  #   iam.gke.io/gcp-service-account: my-app-sa@project.iam.gserviceaccount.com

# Pod Security Context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  seccompProfile:
    type: RuntimeDefault

# Container Security Context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
  protocol: TCP
  name: http
  annotations: {}
  # For LoadBalancer on GCP
  # type: LoadBalancer
  # annotations:
  #   cloud.google.com/load-balancer-type: "External"

# Ingress configuration
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "20"
    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Referrer-Policy: strict-origin-when-cross-origin";
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: my-app-tls
      hosts:
        - my-app.example.com

# Resource limits and requests
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Horizontal Pod Autoscaler
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
  # Custom metrics (requires metrics server)
  metrics: []
  # - type: Pods
  #   pods:
  #     metric:
  #       name: http_requests_per_second
  #     target:
  #       type: AverageValue
  #       averageValue: 1k

# Pod Disruption Budget
podDisruptionBudget:
  enabled: true
  minAvailable: 2
  # maxUnavailable: 1

# Health checks
livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 3

# Startup probe for slow-starting containers
startupProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 30

# Node selection
nodeSelector: {}
  # disktype: ssd
  # node-role.kubernetes.io/worker: "true"

# Tolerations for pod assignment
tolerations: []
# - key: "spot"
#   operator: "Equal"
#   value: "true"
#   effect: "NoSchedule"

# Affinity rules
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - my-app
        topologyKey: kubernetes.io/hostname

# Pod management policy
podManagementPolicy: Parallel

# Update strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0

# Environment variables
env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
  - name: PORT
    value: "8080"

# Environment from ConfigMaps/Secrets
envFrom: []
# - configMapRef:
#     name: app-config
# - secretRef:
#     name: app-secrets

# ConfigMap for application configuration
configMap:
  enabled: true
  data:
    nginx.conf: |
      worker_processes auto;
      error_log /var/log/nginx/error.log warn;
      pid /tmp/nginx.pid;
      
      events {
          worker_connections 1024;
          use epoll;
          multi_accept on;
      }
      
      http {
          include /etc/nginx/mime.types;
          default_type application/octet-stream;
          
          # Security headers
          server_tokens off;
          
          # Logging
          log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';
          
          access_log /var/log/nginx/access.log main;
          
          # Performance
          sendfile on;
          tcp_nopush on;
          tcp_nodelay on;
          keepalive_timeout 65;
          types_hash_max_size 2048;
          client_max_body_size 20M;
          
          # Gzip compression
          gzip on;
          gzip_vary on;
          gzip_proxied any;
          gzip_comp_level 6;
          gzip_types text/plain text/css text/xml text/javascript 
                     application/x-javascript application/xml+rss 
                     application/javascript application/json;
          
          # Rate limiting
          limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
          
          server {
              listen 8080;
              server_name _;
              
              # Security
              add_header X-Frame-Options "SAMEORIGIN" always;
              add_header X-Content-Type-Options "nosniff" always;
              add_header X-XSS-Protection "1; mode=block" always;
              
              location / {
                  root /usr/share/nginx/html;
                  index index.html index.htm;
                  try_files $uri $uri/ =404;
              }
              
              location /healthz {
                  access_log off;
                  return 200 "healthy\n";
                  add_header Content-Type text/plain;
              }
              
              location /ready {
                  access_log off;
                  return 200 "ready\n";
                  add_header Content-Type text/plain;
              }
              
              # Prometheus metrics
              location /metrics {
                  stub_status on;
                  access_log off;
              }
          }
      }

# Secrets (use external secrets in production)
secrets:
  enabled: false
  data: {}
    # API_KEY: "base64-encoded-secret"
    # DB_PASSWORD: "base64-encoded-password"

# Volume mounts
volumeMounts:
  - name: config
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
    readOnly: true
  - name: cache
    mountPath: /var/cache/nginx
  - name: tmp
    mountPath: /tmp
  - name: var-log
    mountPath: /var/log/nginx

# Volumes
volumes:
  - name: config
    configMap:
      name: "{{ include \"my-app-chart.fullname\" . }}"
  - name: cache
    emptyDir: {}
  - name: tmp
    emptyDir: {}
  - name: var-log
    emptyDir: {}

# Persistent Volume Claims
persistence:
  enabled: false
  # storageClass: "standard-rwo"
  # accessMode: ReadWriteOnce
  # size: 10Gi
  # annotations: {}

# Network Policies
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: ingress-nginx
      - namespaceSelector:
          matchLabels:
            name: monitoring
      ports:
      - protocol: TCP
        port: 8080
  egress:
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
    - to:
      - namespaceSelector:
          matchLabels:
            name: kube-system
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53

# ServiceMonitor for Prometheus
serviceMonitor:
  enabled: true
  interval: 30s
  scrapeTimeout: 10s
  labels:
    release: prometheus
  relabelings: []
  metricRelabelings: []

# Pod lifecycle hooks
lifecycle: {}
  # preStop:
  #   exec:
  #     command: ["/bin/sh", "-c", "sleep 15"]
  # postStart:
  #   exec:
  #     command: ["/bin/sh", "-c", "echo 'Container started'"]

# Init containers
initContainers: []
# - name: init-myservice
#   image: busybox:1.35
#   command: ['sh', '-c', "until nslookup myservice.namespace.svc.cluster.local; do echo waiting for myservice; sleep 2; done"]

# Sidecar containers
sidecarContainers: []
# - name: log-collector
#   image: fluentbit/fluent-bit:2.0
#   volumeMounts:
#   - name: var-log
#     mountPath: /var/log/nginx

# Pod labels
podLabels:
  app.kubernetes.io/name: my-app
  app.kubernetes.io/component: web
  app.kubernetes.io/part-of: my-app-suite
  version: "1.0.0"

# Pod annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

# Priority Class
priorityClassName: ""
# priorityClassName: "high-priority"

# DNS Policy and Config
dnsPolicy: ClusterFirst
dnsConfig: {}
  # options:
  # - name: ndots
  #   value: "2"

# Host aliases
hostAliases: []
# - ip: "127.0.0.1"
#   hostnames:
#   - "foo.local"

# Termination Grace Period
terminationGracePeriodSeconds: 30

# RBAC
rbac:
  create: true
  rules: []
  # - apiGroups: [""]
  #   resources: ["configmaps", "secrets"]
  #   verbs: ["get", "list", "watch"]

# Extra manifests to deploy
extraManifests: []
# - apiVersion: v1
#   kind: ConfigMap
#   metadata:
#     name: extra-cm
#   data:
#     key: value
EOF

echo "✅ Created values.yaml"

# Create values-prod.yaml
cat > values-prod.yaml << 'EOF'
# Production-specific values for my-app-chart
# This overrides the default values.yaml

# Use your private registry
image:
  repository: us-west2-docker.pkg.dev/poc-project-463913/brinek-registry/my-app
  tag: "1.0.0"
  pullPolicy: Always

# Image pull secrets for private registry
imagePullSecrets:
  - name: gcr-secret

# Production replicas
replicaCount: 3

# Production domain
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: my-app.prod.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: my-app-prod-tls
      hosts:
        - my-app.prod.example.com

# Production resources
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

# Production autoscaling
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 70

# Production environment variables
env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "warn"
  - name: ENABLE_PROFILING
    value: "false"

# Production node selector
nodeSelector:
  node-role.kubernetes.io/worker: "true"
  node-type: "primary"

# Production tolerations
tolerations: []

# Production affinity - spread across zones
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - my-app
      topologyKey: topology.kubernetes.io/zone

# Production PDB
podDisruptionBudget:
  enabled: true
  minAvailable: 2

# Production monitoring
serviceMonitor:
  enabled: true
  interval: 15s

# Production namespace
namespace:
  create: true
  name: my-app-prod
EOF

echo "✅ Created values-prod.yaml"

# Create values-dev.yaml
cat > values-dev.yaml << 'EOF'
# Development-specific values for my-app-chart

replicaCount: 1

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

autoscaling:
  enabled: false

podDisruptionBudget:
  enabled: false

env:
  - name: APP_ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"
  - name: DEBUG
    value: "true"

namespace:
  create: true
  name: my-app-dev
EOF

echo "✅ Created values-dev.yaml"

# Create .helmignore
cat > .helmignore << 'EOF'
# Patterns to ignore when building packages.
# This supports shell glob matching, relative path matching, and
# negation (prefixed with !). Only one pattern per line.
.DS_Store
# Common VCS dirs
.git/
.gitignore
.bzr/
.bzrignore
.hg/
.hgignore
.svn/
# Common backup files
*.swp
*.bak
*.tmp
*.orig
*~
# Various IDEs
.project
.idea/
*.tmproj
.vscode/
# Project specific
*.md
.helmignore
values-*.yaml
tests/
ci/
EOF

echo "✅ Created .helmignore"

# Create README.md
cat > README.md << 'EOF'
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
EOF

echo "✅ Created README.md"

# Create templates/_helpers.tpl
cat > templates/_helpers.tpl << 'EOF'
{{/*
Expand the name of the chart.
*/}}
{{- define "my-app-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-app-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "my-app-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-app-chart.labels" -}}
helm.sh/chart: {{ include "my-app-chart.chart" . }}
{{ include "my-app-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "my-app-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "my-app-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "my-app-chart.image" -}}
{{- $registryName := .Values.image.repository -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}

{{/*
Return the namespace
*/}}
{{- define "my-app-chart.namespace" -}}
{{- if .Values.namespace.create -}}
{{- .Values.namespace.name -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end }}
EOF

echo "✅ Created templates/_helpers.tpl"

# Create templates/namespace.yaml
cat > templates/namespace.yaml << 'EOF'
{{- if .Values.namespace.create -}}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace.name }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
    {{- with .Values.namespace.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .Values.namespace.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
EOF

echo "✅ Created templates/namespace.yaml"

# Create templates/deployment.yaml
cat > templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  strategy:
    {{- toYaml .Values.strategy | nindent 4 }}
  selector:
    matchLabels:
      {{- include "my-app-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "my-app-chart.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "my-app-chart.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      {{- if .Values.priorityClassName }}
      priorityClassName: {{ .Values.priorityClassName }}
      {{- end }}
      {{- if .Values.dnsPolicy }}
      dnsPolicy: {{ .Values.dnsPolicy }}
      {{- end }}
      {{- with .Values.dnsConfig }}
      dnsConfig:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.hostAliases }}
      hostAliases:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
      {{- with .Values.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: {{ include "my-app-chart.image" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: {{ .Values.service.protocol }}
          {{- if .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if .Values.startupProbe }}
          startupProbe:
            {{- toYaml .Values.startupProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- with .Values.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.lifecycle }}
          lifecycle:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        {{- with .Values.sidecarContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF

echo "✅ Created templates/deployment.yaml"

# Create templates/service.yaml
cat > templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: {{ .Values.service.protocol }}
      name: {{ .Values.service.name }}
  selector:
    {{- include "my-app-chart.selectorLabels" . | nindent 4 }}
EOF

echo "✅ Created templates/service.yaml"

# Create templates/ingress.yaml
cat > templates/ingress.yaml << 'EOF'
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "my-app-chart.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
EOF

echo "✅ Created templates/ingress.yaml"

# Create templates/hpa.yaml
cat > templates/hpa.yaml << 'EOF'
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "my-app-chart.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- with .Values.autoscaling.metrics }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end }}
EOF

echo "✅ Created templates/hpa.yaml"

# Create templates/pdb.yaml
cat > templates/pdb.yaml << 'EOF'
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
spec:
  {{- if .Values.podDisruptionBudget.minAvailable }}
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if .Values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-app-chart.selectorLabels" . | nindent 6 }}
{{- end }}
EOF

echo "✅ Created templates/pdb.yaml"

# Create templates/configmap.yaml
cat > templates/configmap.yaml << 'EOF'
{{- if .Values.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
data:
  {{- with .Values.configMap.data }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
EOF

echo "✅ Created templates/configmap.yaml"

# Create templates/secret.yaml
cat > templates/secret.yaml << 'EOF'
{{- if .Values.secrets.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
type: Opaque
data:
  {{- with .Values.secrets.data }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
EOF

echo "✅ Created templates/secret.yaml"

# Create templates/serviceaccount.yaml
cat > templates/serviceaccount.yaml << 'EOF'
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "my-app-chart.serviceAccountName" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
EOF

echo "✅ Created templates/serviceaccount.yaml"

# Create templates/role.yaml
cat > templates/role.yaml << 'EOF'
{{- if and .Values.rbac.create (gt (len .Values.rbac.rules) 0) }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
rules:
  {{- toYaml .Values.rbac.rules | nindent 2 }}
{{- end }}
EOF

echo "✅ Created templates/role.yaml"

# Create templates/rolebinding.yaml
cat > templates/rolebinding.yaml << 'EOF'
{{- if and .Values.rbac.create (gt (len .Values.rbac.rules) 0) }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "my-app-chart.fullname" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "my-app-chart.serviceAccountName" . }}
    namespace: {{ include "my-app-chart.namespace" . }}
{{- end }}
EOF

echo "✅ Created templates/rolebinding.yaml"

# Create templates/networkpolicy.yaml
cat > templates/networkpolicy.yaml << 'EOF'
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "my-app-chart.selectorLabels" . | nindent 6 }}
  policyTypes:
    {{- toYaml .Values.networkPolicy.policyTypes | nindent 4 }}
  {{- with .Values.networkPolicy.ingress }}
  ingress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.networkPolicy.egress }}
  egress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
EOF

echo "✅ Created templates/networkpolicy.yaml"

# Create templates/servicemonitor.yaml
cat > templates/servicemonitor.yaml << 'EOF'
{{- if .Values.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "my-app-chart.fullname" . }}
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
    {{- with .Values.serviceMonitor.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "my-app-chart.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: {{ .Values.service.name }}
      path: /metrics
      interval: {{ .Values.serviceMonitor.interval }}
      scrapeTimeout: {{ .Values.serviceMonitor.scrapeTimeout }}
      {{- with .Values.serviceMonitor.relabelings }}
      relabelings:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.serviceMonitor.metricRelabelings }}
      metricRelabelings:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
EOF

echo "✅ Created templates/servicemonitor.yaml"

# Create templates/NOTES.txt
cat > templates/NOTES.txt << 'EOF'
1. Get the application URL by running these commands:
{{- if .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
  {{- range .paths }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}{{ .path }}
  {{- end }}
{{- end }}
{{- else if contains "NodePort" .Values.service.type }}
  export NODE_PORT=$(kubectl get --namespace {{ include "my-app-chart.namespace" . }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "my-app-chart.fullname" . }})
  export NODE_IP=$(kubectl get nodes --namespace {{ include "my-app-chart.namespace" . }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
{{- else if contains "LoadBalancer" .Values.service.type }}
     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get --namespace {{ include "my-app-chart.namespace" . }} svc -w {{ include "my-app-chart.fullname" . }}'
  export SERVICE_IP=$(kubectl get svc --namespace {{ include "my-app-chart.namespace" . }} {{ include "my-app-chart.fullname" . }} --template "{{"{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"}}")
  echo http://$SERVICE_IP:{{ .Values.service.port }}
{{- else if contains "ClusterIP" .Values.service.type }}
  export POD_NAME=$(kubectl get pods --namespace {{ include "my-app-chart.namespace" . }} -l "app.kubernetes.io/name={{ include "my-app-chart.name" . }},app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace {{ include "my-app-chart.namespace" . }} $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace {{ include "my-app-chart.namespace" . }} port-forward $POD_NAME 8080:$CONTAINER_PORT
{{- end }}

2. Check the deployment status:
  kubectl get deployment {{ include "my-app-chart.fullname" . }} -n {{ include "my-app-chart.namespace" . }}

3. View the logs:
  kubectl logs -l app.kubernetes.io/name={{ include "my-app-chart.name" . }} -n {{ include "my-app-chart.namespace" . }}

4. Scale the deployment:
  kubectl scale deployment {{ include "my-app-chart.fullname" . }} --replicas=5 -n {{ include "my-app-chart.namespace" . }}

{{- if .Values.autoscaling.enabled }}
5. HPA Status:
  kubectl get hpa {{ include "my-app-chart.fullname" . }} -n {{ include "my-app-chart.namespace" . }}
{{- end }}

{{- if .Values.serviceMonitor.enabled }}
6. Prometheus metrics available at:
  http://{{ include "my-app-chart.fullname" . }}.{{ include "my-app-chart.namespace" . }}.svc.cluster.local:{{ .Values.service.port }}/metrics
{{- end }}
EOF

echo "✅ Created templates/NOTES.txt"

# Create templates/tests/test-connection.yaml
cat > templates/tests/test-connection.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-app-chart.fullname" . }}-test-connection"
  namespace: {{ include "my-app-chart.namespace" . }}
  labels:
    {{- include "my-app-chart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox:1.35
      command: ['wget']
      args: ['{{ include "my-app-chart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
EOF

echo "✅ Created templates/tests/test-connection.yaml"

echo "
🎉 Helm chart created successfully!

📂 Directory structure:
$(tree -L 2 || find . -type f | sed 's|^\./||' | sort)

📋 Next steps:
1. Review and customize the values in values.yaml
2. Test the chart: helm lint .
3. Deploy: helm install my-app . --dry-run --debug
4. Install: helm install my-app . --create-namespace

💡 To deploy with your custom image:
   - Update image.repository in values.yaml
   - Set your image tag
   - Deploy: helm install my-app .
"