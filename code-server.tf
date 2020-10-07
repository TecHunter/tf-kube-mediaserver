resource "kubernetes_namespace" "code-server" {
  metadata {
    name = "code-server"
  }
}

resource "kubernetes_deployment" "code-server" {
  metadata {
    name = "code-server"
    labels = {
      app = "code-server"
    }
    namespace = kubernetes_namespace.code-server.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "code-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "code-server"
        }
      }

      spec {
        container {
          image             = "codercom/code-server:latest"
          image_pull_policy = "Always"
          name              = "code-server"

          port {
            container_port = 8080
          }
          env {
            name  = "PASSWORD"
            value = "ultimate"
          }

        }

      }
    }
  }
}

resource "kubernetes_service" "code-server" {
  metadata {
    name      = "code-server"
    namespace = kubernetes_namespace.code-server.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.code-server.spec.0.template.0.metadata.0.labels.app
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "code-server" {
  depends_on = [helm_release.ingress]
  metadata {
    name      = "code-server"
    namespace = kubernetes_namespace.code-server.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      #"cert-manager.io/cluster-issuer"              = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
    }
  }

  spec {
    rule {
      host = "code.techunter.io"
      http {
        path {
          backend {
            service_name = kubernetes_service.code-server.metadata.0.name
            service_port = kubernetes_service.code-server.spec.0.port.0.port
          }
        }
      }
    }
  }
  #  wait_for_load_balancer = true
}
