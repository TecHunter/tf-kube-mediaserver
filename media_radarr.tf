
resource "kubernetes_deployment" "radarr" {
  metadata {
    name = "radarr"
    labels = {
      app         = "radarr"
      hasDownload = "true"
      hasConfig   = "true"
    }
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "radarr"
      }
    }

    template {
      metadata {
        labels = {
          app = "radarr"
        }
      }

      spec {
        container {
          image = "linuxserver/radarr"
          name  = "radarr"

          port {
            container_port = 7878
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
          
          volume_mount {
            mount_path = "/config"
            sub_path   = "radarr/config"
            name       = "config-vol"
          }
          volume_mount {
            mount_path = "/movies"
            sub_path = "Movies"
            name       = "media-vol"
          }
        }
        volume {
          name = "config-vol"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.tank-config-claim.metadata.0.name
          }
        }
        volume {
          name = "media-vol"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.tank-media-claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "radarr" {
  metadata {
    name = "radarr"
    namespace = kubernetes_namespace.media.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.radarr.spec.0.template.0.metadata.0.labels.app
    }
    
    port {
      port        = 7878
      target_port = 7878
    }

    type = "ClusterIP"
  }
}