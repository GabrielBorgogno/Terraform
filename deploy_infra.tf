
resource "time_sleep" "wait_for_kubernetes" {
  create_duration = "20s"
}

resource "kubernetes_namespace" "kube_namespace" {
  depends_on = [time_sleep.wait_for_kubernetes]
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.kube_namespace]
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.kube_namespace.metadata[0].name
  create_namespace = true
  version    = "25.26.0"
  timeout = 2000


  set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  set {
    name  = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}

 resource "helm_release" "grafana" {
  depends_on = [kubernetes_namespace.kube_namespace]
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.5.0"
  namespace  = kubernetes_namespace.kube_namespace.metadata[0].name
  create_namespace = true
  timeout = 2000
  


set {
  name  = "grafana\\.resources"
  value = yamlencode({
    limits = {
      cpu    = "200m"
      memory = "50Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "30Mi"
    }
  })
}

}