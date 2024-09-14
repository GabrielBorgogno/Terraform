# Configure o provedor de cloud (neste caso, o Kubernetes)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Crie um namespace para o monitoramento
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Instale o Helm no cluster
resource "helm_release" "helm" {
  name       = "helm"
  repository = "https://charts.helm.sh/stable"
  chart      = "helm"
  version    = "3.5.4"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}

# Instale o Prometheus com Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "14.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]
}

# Instale o Grafana com Helm
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.10.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values/grafana-values.yaml")
  ]
}

# Crie um ServiceAccount para o Prometheus
resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

# Crie um ClusterRole para o Prometheus
resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# Crie um ClusterRoleBinding para o Prometheus
resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus.metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}