# modules/k8s-addons/outputs.tf

output "nginx_ingress_status" {
  description = "Status of NGINX Ingress installation"
  value       = var.install_nginx_ingress ? helm_release.nginx_ingress[0].status : "not installed"
}

output "nginx_ingress_lb_ip" {
  description = "Load balancer IP of NGINX Ingress"
  value       = var.install_nginx_ingress ? "Run: kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" : null
}

output "cert_manager_status" {
  description = "Status of cert-manager installation"
  value       = var.install_cert_manager ? helm_release.cert_manager[0].status : "not installed"
}

output "external_dns_status" {
  description = "Status of ExternalDNS installation"
  value       = var.install_external_dns && var.dns_zone_name != "" ? helm_release.external_dns[0].status : "not installed"
}

output "cluster_autoscaler_status" {
  description = "Status of Cluster Autoscaler installation"
  value       = var.install_cluster_autoscaler ? "deployed" : "not installed"
}

output "metrics_server_status" {
  description = "Status of Metrics Server installation"
  value       = var.install_metrics_server ? helm_release.metrics_server[0].status : "not installed"
}

output "prometheus_status" {
  description = "Status of Prometheus installation"
  value       = var.install_prometheus ? helm_release.prometheus[0].status : "not installed"
}

output "grafana_status" {
  description = "Status of Grafana installation"
  value       = var.install_grafana ? helm_release.grafana[0].status : "not installed"
}

output "grafana_admin_password_secret" {
  description = "Secret Manager secret containing Grafana admin password"
  value       = var.install_grafana ? google_secret_manager_secret.grafana_admin_password[0].name : null
}

output "argocd_status" {
  description = "Status of ArgoCD installation"
  value       = var.install_argocd ? helm_release.argocd[0].status : "not installed"
}

output "argocd_initial_password_command" {
  description = "Command to get ArgoCD initial admin password"
  value       = var.install_argocd ? "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : null
}

output "installed_namespaces" {
  description = "List of namespaces created for addons"
  value = compact([
    var.install_nginx_ingress ? "ingress-nginx" : "",
    var.install_cert_manager ? "cert-manager" : "",
    var.install_external_dns ? "external-dns" : "",
    (var.install_prometheus || var.install_grafana) ? var.prometheus_namespace : "",
    var.install_argocd ? var.argocd_namespace : ""
  ])
}

output "helm_releases" {
  description = "Information about deployed Helm releases"
  value = {
    nginx_ingress = var.install_nginx_ingress ? {
      name      = helm_release.nginx_ingress[0].name
      namespace = helm_release.nginx_ingress[0].namespace
      version   = helm_release.nginx_ingress[0].version
    } : null
    cert_manager = var.install_cert_manager ? {
      name      = helm_release.cert_manager[0].name
      namespace = helm_release.cert_manager[0].namespace
      version   = helm_release.cert_manager[0].version
    } : null
    external_dns = var.install_external_dns && var.dns_zone_name != "" ? {
      name      = helm_release.external_dns[0].name
      namespace = helm_release.external_dns[0].namespace
      version   = helm_release.external_dns[0].version
    } : null
    metrics_server = var.install_metrics_server ? {
      name      = helm_release.metrics_server[0].name
      namespace = helm_release.metrics_server[0].namespace
      version   = helm_release.metrics_server[0].version
    } : null
    prometheus = var.install_prometheus ? {
      name      = helm_release.prometheus[0].name
      namespace = helm_release.prometheus[0].namespace
      version   = helm_release.prometheus[0].version
    } : null
    grafana = var.install_grafana ? {
      name      = helm_release.grafana[0].name
      namespace = helm_release.grafana[0].namespace
      version   = helm_release.grafana[0].version
    } : null
    argocd = var.install_argocd ? {
      name      = helm_release.argocd[0].name
      namespace = helm_release.argocd[0].namespace
      version   = helm_release.argocd[0].version
    } : null
  }
}