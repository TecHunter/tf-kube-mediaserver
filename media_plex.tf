

resource "kubernetes_secret" "plex-token" {
  metadata {
    name      = "plex-token"
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  data = {
    PLEX_CLAIM = base64encode(var.plex_claim)
  }

}

resource "kubernetes_deployment" "plex" {
  metadata {
    name = "plex"
    labels = {
      app         = "plex"
      hasDownload = "true"
      hasConfig   = "true"
    }
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "plex"
      }
    }

    template {
      metadata {
        labels = {
          app = "plex"
        }
      }

      spec {
        container {
          image = "plexinc/pms-docker:plexpass"
          name  = "plex"

          port {
            container_port = 32400
          }
          
          dynamic "port" {
            for_each = var.plex_ports
            content {
              container_port = port.value
            }
          }
          
          env {
            name  = "PGID"
            value = "1000"
          }
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "TZ"
            value = "Europe/Paris"
          }
          
          env {
            name = "PLEX_CLAIM"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.plex-token.metadata.0.name
                key      = "PLEX_CLAIM"
                optional = false
              }
            }
          }

          volume_mount {
            mount_path = "/config"
            sub_path   = "plex/config"
            name       = kubernetes_persistent_volume_claim.tank-config-claim.metadata.0.name
          }
          volume_mount {
            mount_path = "/data"
            name       = kubernetes_persistent_volume_claim.tank-media-claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "plex" {
  metadata {
    name = "plex"
    namespace = kubernetes_namespace.media.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.plex.spec.0.template.0.metadata.0.labels.app
    }
    
    port {
      port        = 32400
      target_port = 32400
    }

    type = "LoadBalancer"
  }
}