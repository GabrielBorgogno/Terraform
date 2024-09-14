provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}


resource "helm_release" "helm" {
  name       = "helm"
  repository = "https://charts.helm.sh/stable"
  chart      = "helm"
  version    = "3.5.4"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "14.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    "https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/prometheus/values.yaml"
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.10.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    "https://raw.githubusercontent.com/grafana/helm-charts/main/charts/grafana/values.yaml"
  ]
}

resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

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