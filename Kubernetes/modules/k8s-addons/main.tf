# modules/k8s-addons/main.tf

# We receive cluster details as variables, no need for data source

# Namespaces
resource "kubernetes_namespace" "ingress_nginx" {
  count = var.install_nginx_ingress ? 1 : 0
  
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0
  
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "external_dns" {
  count = var.install_external_dns ? 1 : 0
  
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_namespace" "monitoring" {
  count = (var.install_prometheus || var.install_grafana) ? 1 : 0
  
  metadata {
    name = var.prometheus_namespace
  }
}

resource "kubernetes_namespace" "argocd" {
  count = var.install_argocd ? 1 : 0
  
  metadata {
    name = var.argocd_namespace
  }
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  count = var.install_nginx_ingress ? 1 : 0
  
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_version
  namespace  = kubernetes_namespace.ingress_nginx[0].metadata[0].name
  
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
  
  set {
    name  = "controller.podAnnotations.prometheus\\.io/scrape"
    value = "true"
  }
  
  set {
    name  = "controller.podAnnotations.prometheus\\.io/port"
    value = "10254"
  }
}

# cert-manager
resource "helm_release" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0
  
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name
  
  set {
    name  = "installCRDs"
    value = "true"
  }
  
  set {
    name  = "prometheus.enabled"
    value = "true"
  }
}

# ExternalDNS
resource "helm_release" "external_dns" {
  count = var.install_external_dns && var.dns_zone_name != "" ? 1 : 0
  
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_version
  namespace  = kubernetes_namespace.external_dns[0].metadata[0].name
  
  set {
    name  = "provider"
    value = "google"
  }
  
  set {
    name  = "google.project"
    value = var.project_id
  }
  
  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }
  
  set {
    name  = "policy"
    value = "sync"
  }
  
  set {
    name  = "rbac.create"
    value = "true"
  }
}

# Metrics Server
resource "helm_release" "metrics_server" {
  count = var.install_metrics_server ? 1 : 0
  
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"
  
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}

# Prometheus
resource "helm_release" "prometheus" {
  count = var.install_prometheus ? 1 : 0
  
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.prometheus_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  
  values = [
    <<-EOT
    alertmanager:
      persistentVolume:
        size: 10Gi
    server:
      persistentVolume:
        size: 50Gi
      service:
        type: ClusterIP
    pushgateway:
      persistentVolume:
        size: 2Gi
    EOT
  ]
}

# Grafana
resource "helm_release" "grafana" {
  count = var.install_grafana ? 1 : 0
  
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.grafana_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  
  values = [
    <<-EOT
    persistence:
      enabled: true
      size: 10Gi
    adminPassword: ${random_password.grafana_admin[0].result}
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server.${var.prometheus_namespace}.svc.cluster.local
          access: proxy
          isDefault: true
    EOT
  ]
  
  depends_on = [helm_release.prometheus]
}

# Random password for Grafana admin
resource "random_password" "grafana_admin" {
  count   = var.install_grafana ? 1 : 0
  length  = 16
  special = true
}

# Store Grafana password in Secret Manager
resource "google_secret_manager_secret" "grafana_admin_password" {
  count     = var.install_grafana ? 1 : 0
  secret_id = "${var.cluster_name}-grafana-admin-password"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "grafana_admin_password" {
  count  = var.install_grafana ? 1 : 0
  secret = google_secret_manager_secret.grafana_admin_password[0].id
  
  secret_data = random_password.grafana_admin[0].result
}

# ArgoCD
resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd[0].metadata[0].name
  
  values = [
    <<-EOT
    server:
      service:
        type: ClusterIP
      extraArgs:
        - --insecure
    configs:
      params:
        server.insecure: true
    EOT
  ]
}

# Cluster Autoscaler (Note: GKE has built-in autoscaling, this is optional)
resource "kubernetes_deployment" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0
  
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      app = "cluster-autoscaler"
    }
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8085"
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.cluster_autoscaler[0].metadata[0].name
        
        container {
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v1.27.0"
          name  = "cluster-autoscaler"
          
          resources {
            limits = {
              cpu    = "100m"
              memory = "300Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "300Mi"
            }
          }
          
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=gce",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=mig:name=${var.cluster_name}",
            "--balance-similar-node-groups",
            "--skip-nodes-with-system-pods=false"
          ]
          
          env {
            name  = "GOOGLE_APPLICATION_CREDENTIALS"
            value = "/var/secrets/google/key.json"
          }
          
          volume_mount {
            name       = "google-cloud-key"
            mount_path = "/var/secrets/google"
            read_only  = true
          }
        }
        
        volume {
          name = "google-cloud-key"
          secret {
            secret_name = kubernetes_secret.cluster_autoscaler_sa_key[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Service Account for Cluster Autoscaler
resource "kubernetes_service_account" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0
  
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}

# Cluster Role for Cluster Autoscaler
resource "kubernetes_cluster_role" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0
  
  metadata {
    name = "cluster-autoscaler"
  }
  
  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "update"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch", "update"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["apps", "extensions"]
    resources  = ["daemonsets", "replicasets", "statefulsets", "deployments"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs      = ["get", "list", "watch"]
  }
}

# Cluster Role Binding for Cluster Autoscaler
resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0
  
  metadata {
    name = "cluster-autoscaler"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_autoscaler[0].metadata[0].name
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler[0].metadata[0].name
    namespace = "kube-system"
  }
}

# GCP Service Account for Cluster Autoscaler
resource "google_service_account" "cluster_autoscaler" {
  count        = var.install_cluster_autoscaler ? 1 : 0
  account_id   = substr("${var.cluster_name}-ca", 0, 30)  # Ensure it's under 30 chars
  display_name = "Cluster Autoscaler Service Account"
  project      = var.project_id
}

# IAM binding for Cluster Autoscaler
resource "google_project_iam_member" "cluster_autoscaler" {
  count   = var.install_cluster_autoscaler ? 1 : 0
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.cluster_autoscaler[0].email}"
}

# Service Account Key for Cluster Autoscaler
resource "google_service_account_key" "cluster_autoscaler" {
  count              = var.install_cluster_autoscaler ? 1 : 0
  service_account_id = google_service_account.cluster_autoscaler[0].name
}

# Kubernetes Secret for Cluster Autoscaler Service Account Key
resource "kubernetes_secret" "cluster_autoscaler_sa_key" {
  count = var.install_cluster_autoscaler ? 1 : 0
  
  metadata {
    name      = "cluster-autoscaler-cloud-provider"
    namespace = "kube-system"
  }
  
  data = {
    "key.json" = base64decode(google_service_account_key.cluster_autoscaler[0].private_key)
  }
}