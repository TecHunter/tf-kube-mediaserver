
resource "kubernetes_ingress" "media" {
  metadata {
    name      = "media-ingress"
    namespace = kubernetes_namespace.media.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class"                 = "nginx"
      "cert-manager.io/cluster-issuer"              = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
    }
  }

  spec {
    rule {
      host = "media.techunter.io"
      http {
        path {
          backend {
            service_name = kubernetes_service.torrent-client.metadata.0.name
            service_port = kubernetes_service.torrent-client.spec.0.port.0.port
          }

          path = "/torrent"
        }
        
        path {
          backend {
            service_name = kubernetes_service.sonarr.metadata.0.name
            service_port = kubernetes_service.sonarr.spec.0.port.0.port
          }

          path = "/sonarr"
        }
        
        path {
          backend {
            service_name = kubernetes_service.radarr.metadata.0.name
            service_port = kubernetes_service.radarr.spec.0.port.0.port
          }

          path = "/radarr"
        }
        
        path {
          backend {
            service_name = kubernetes_service.jackett.metadata.0.name
            service_port = kubernetes_service.jackett.spec.0.port.0.port
          }

          path = "/jackett"
        }
        
        path {
          backend {
            service_name = kubernetes_service.plex.metadata.0.name
            service_port = kubernetes_service.plex.spec.0.port.0.port
          }

          path = "/"
        }
      }
    }

    tls {
      secret_name = "tls-secret"
    }
  }
}
