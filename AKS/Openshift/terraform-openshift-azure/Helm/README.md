# 🚀 NGINX CloudLens Helm Chart for OpenShift

A production-ready Helm chart that deploys NGINX with a beautiful custom welcome page across all worker nodes in your OpenShift cluster.

![Status](https://img.shields.io/badge/Status-Production%20Ready-green)
![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red)
![Helm](https://img.shields.io/badge/Helm-3.x-blue)

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [What Makes It Work](#what-makes-it-work)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Deployment Guide](#deployment-guide)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)
- [Security Considerations](#security-considerations)

## 🌟 Overview

This Helm chart deploys:
- **9 NGINX pods** (3 per worker node) using DaemonSets
- **Beautiful animated welcome page** with gradient backgrounds and particle effects
- **Dual protocol support** (HTTP and HTTPS) without redirects
- **Full OpenShift integration** with Routes, SCCs, and proper security contexts

## ✨ Features

### Visual Features
- 🎨 **Animated rainbow text** saying "Welcome to Keysight OpenShift Cluster"
- 🌈 **Purple gradient background** with floating particles
- 💫 **Pulsing logo** with gradient effects
- 📊 **Live pod information** display with glassmorphism effect

### Technical Features
- ⚡ **DaemonSet deployment** - Ensures exactly 3 pods per worker node
- 🔒 **Security Context Constraints** - Properly configured for OpenShift
- 📡 **Dual protocol access** - Both HTTP and HTTPS work independently
- 📊 **Prometheus metrics** - Via nginx-exporter sidecar
- 🔄 **Health checks** - Liveness and readiness probes
- 🛡️ **Network policies** - Secure pod communication

## 📦 Prerequisites

```bash
# 1. OpenShift 4.x cluster
oc version

# 2. Helm 3.x installed
helm version

# 3. Logged into OpenShift
oc login https://api.your-cluster.com:6443
oc whoami

# 4. Sufficient permissions
oc auth can-i create namespace
oc auth can-i create securitycontextconstraints
```

## 🚀 Quick Start

```bash
# Clone or download the Helm chart
cd nginx-cloudlens/

# Deploy with one command
helm upgrade --install nginx-cloudlens . \
  --create-namespace \
  --namespace cloudlens \
  --wait \
  --timeout 10m

# Get the URL
echo "Access at: http://$(oc get route nginx-cloudlens -n cloudlens -o jsonpath='{.spec.host}')"
```

## 🔧 What Makes It Work

### 1. **Security Context Fix** ⚡
The biggest challenge was OpenShift's Security Context Constraints (SCCs).

**Problem**: Pods tried to run as user 1001, but OpenShift requires UIDs in range [1000770000, 1000779999]

**Solution**: Grant the service account permission to use `anyuid` SCC:
```bash
oc adm policy add-scc-to-user anyuid -z nginx-cloudlens -n cloudlens
```

### 2. **Route Configuration Fix** 🌐
**Problem**: Initial route pointed to port 8443 with edge termination, causing "400 Bad Request"

**Solution**: Point route to port 8080 with `insecureEdgeTerminationPolicy: Allow`:
```yaml
spec:
  port:
    targetPort: 8080  # Changed from 8443
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Allow  # Changed from Redirect
```

### 3. **Namespace Management Fix** 📁
**Problem**: Helm namespace creation conflicts

**Solution**: Use `--create-namespace` flag and let Helm manage it:
```bash
helm install nginx-cloudlens . --create-namespace --namespace cloudlens
```

### 4. **DaemonSet Node Selector** 🖥️
**Key**: DaemonSets use proper node selector to target only worker nodes:
```yaml
nodeSelector:
  node-role.kubernetes.io/worker: ""
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenShift Cluster                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Worker 1   │  │  Worker 2   │  │  Worker 3   │         │
│  │             │  │             │  │             │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │DaemonSet│ │  │ │DaemonSet│ │  │ │DaemonSet│ │         │
│  │ │    0    │ │  │ │    0    │ │  │ │    0    │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │DaemonSet│ │  │ │DaemonSet│ │  │ │DaemonSet│ │         │
│  │ │    1    │ │  │ │    1    │ │  │ │    1    │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │DaemonSet│ │  │ │DaemonSet│ │  │ │DaemonSet│ │         │
│  │ │    2    │ │  │ │    2    │ │  │ │    2    │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │               Service (LoadBalancer)            │         │
│  └────────────────────────────────────────────────┘         │
│                          │                                   │
│  ┌────────────────────────────────────────────────┐         │
│  │                  OpenShift Route                │         │
│  │  http://nginx-cloudlens.apps.cluster.com       │         │
│  │  https://nginx-cloudlens.apps.cluster.com      │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 📁 File Structure

```
nginx-cloudlens/
├── Chart.yaml                    # Helm chart metadata
├── values.yaml                   # Default configuration values
├── templates/
│   ├── _helpers.tpl             # Template helper functions
│   ├── configmap.yaml           # 🎨 Contains the beautiful HTML/CSS/JS
│   ├── deployment.yaml          # Creates 3 DaemonSets
│   ├── service.yaml             # LoadBalancer service
│   ├── route.yaml               # OpenShift Route for ingress
│   ├── serviceaccount.yaml      # SA + SecurityContextConstraints
│   ├── networkpolicy.yaml       # Network security rules
│   ├── poddisruptionbudget.yaml # High availability settings
│   └── servicemonitor.yaml      # Prometheus monitoring
└── README.md                    # This file
```

### Key Files Explained

#### `templates/configmap.yaml` - The Magic ✨
Contains the entire custom HTML page with:
- **CSS animations** for gradient backgrounds and rainbow text
- **JavaScript** for floating particles
- **Dynamic content** showing pod/node information

#### `templates/deployment.yaml` - The Workload 🏃
- Creates 3 DaemonSets (nginx-cloudlens-0, nginx-cloudlens-1, nginx-cloudlens-2)
- Each DaemonSet runs on all worker nodes
- Includes init containers for HTML setup and TLS certificate generation

#### `templates/route.yaml` - The Access Point 🌐
- Creates OpenShift Route for external access
- Configured for both HTTP and HTTPS without redirects
- Edge TLS termination with `insecureEdgeTerminationPolicy: Allow`

## 📝 Deployment Guide

### Step 1: Prepare Environment
```bash
# Verify you're in the correct cluster
oc cluster-info
oc get nodes

# Check available worker nodes
oc get nodes -l node-role.kubernetes.io/worker
```

### Step 2: Configure Values (Optional)
Edit `values.yaml` if needed:
```yaml
namespace: cloudlens              # Target namespace
deployment:
  podsPerNode: 3                 # Pods per worker node
service:
  type: LoadBalancer             # Service type
route:
  host: nginx-cloudlens.apps.your-cluster.com  # Your route
```

### Step 3: Deploy the Chart
```bash
# Full deployment command with all options
helm upgrade --install nginx-cloudlens . \
  --create-namespace \
  --namespace cloudlens \
  --wait \
  --timeout 10m \
  --debug

# If namespace already exists
helm upgrade --install nginx-cloudlens . \
  --namespace cloudlens \
  --wait
```

### Step 4: Grant Security Permissions
```bash
# This is CRITICAL - without this, pods won't start
oc adm policy add-scc-to-user anyuid -z nginx-cloudlens -n cloudlens
```

### Step 5: Verify Deployment
```bash
# Check pods (should see 9 total - 3 per worker)
oc get pods -n cloudlens

# Check DaemonSets
oc get daemonsets -n cloudlens

# Check services
oc get svc -n cloudlens

# Check route
oc get route -n cloudlens
```

### Step 6: Access the Application
```bash
# Get the URL
ROUTE_URL=$(oc get route nginx-cloudlens -n cloudlens -o jsonpath='{.spec.host}')
echo "HTTP:  http://$ROUTE_URL"
echo "HTTPS: https://$ROUTE_URL"

# Open in browser (macOS)
open "http://$ROUTE_URL"
```

## 🔍 Troubleshooting

### Pods Not Starting
```bash
# Check pod status
oc get pods -n cloudlens
oc describe pod <pod-name> -n cloudlens

# Check events
oc get events -n cloudlens --sort-by='.lastTimestamp'

# Common fix - grant SCC permissions
oc adm policy add-scc-to-user anyuid -z nginx-cloudlens -n cloudlens
```

### 400 Bad Request Error
```bash
# Check route configuration
oc get route nginx-cloudlens -n cloudlens -o yaml

# Ensure targetPort is 8080, not 8443
# Ensure insecureEdgeTerminationPolicy is Allow, not Redirect
```

### Namespace Issues
```bash
# If namespace exists with wrong annotations
oc delete namespace cloudlens
helm install nginx-cloudlens . --create-namespace --namespace cloudlens
```

### Security Context Errors
```bash
# Error: "must be in the ranges: [1000770000, 1000779999]"
# Solution:
oc adm policy add-scc-to-user anyuid -z nginx-cloudlens -n cloudlens
oc rollout restart daemonset -n cloudlens
```

## 🎨 Customization

### Change Colors
Edit `templates/configmap.yaml`:
```css
/* Purple gradient background */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Rainbow text animation */
background: linear-gradient(45deg, #f093fb 0%, #f5576c 25%, #ffa502 50%, #32ff7e 75%, #7bed9f 100%);
```

### Change Welcome Message
In `templates/configmap.yaml`, find:
```html
<h1 class="welcome-text">Welcome to Keysight OpenShift Cluster</h1>
```

### Scale Pods Per Node
In `values.yaml`:
```yaml
deployment:
  podsPerNode: 5  # Change from 3 to 5 pods per node
```

## 🔒 Security Considerations

### Security Context Constraints (SCC)
- Uses `anyuid` SCC to allow custom UIDs
- Runs as non-root user
- Drops unnecessary capabilities
- Uses read-only root filesystem where possible

### Network Policies
- Restricts ingress to OpenShift router
- Allows egress for DNS and HTTPS
- Pod-to-pod communication within namespace

### TLS Configuration
- Self-signed certificates generated automatically
- Edge termination at the route level
- Supports both HTTP and HTTPS independently

## 🧹 Cleanup

```bash
# Uninstall the Helm release
helm uninstall nginx-cloudlens -n cloudlens

# Delete the namespace
oc delete namespace cloudlens

# Remove SCC permissions (if granted)
oc adm policy remove-scc-from-user anyuid -z nginx-cloudlens -n cloudlens
```

## 📊 Monitoring

Access Prometheus metrics:
```bash
# Port-forward to a pod
oc port-forward -n cloudlens pod/$(oc get pod -n cloudlens -o name | head -1 | cut -d/ -f2) 9113:9113

# Access metrics
curl http://localhost:9113/metrics
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Keysight Technologies for the OpenShift cluster
- CloudLens team for the project requirements
- OpenShift community for security best practices

---

**Created with ❤️ by the CloudLens Team**