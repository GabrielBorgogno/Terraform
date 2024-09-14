
resource "time_sleep" "wait_for_kubernetes_argocd" {
  create_duration = "20s"
}

resource "kubernetes_namespace" "kube_namespace_argocd" {
  depends_on = [time_sleep.wait_for_kubernetes_argocd]
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {

  depends_on = [kubernetes_namespace.kube_namespace_argocd]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.kube_namespace_argocd.metadata[0].name
  create_namespace = true
  version    = "7.5.2"
  timeout = 2000

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.localhost"

  
  }


}
