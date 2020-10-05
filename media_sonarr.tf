
resource "kubernetes_deployment" "sonarr" {
  metadata {
    name = "sonarr"
    labels = {
      app         = "sonarr"
      hasDownload = "true"
      hasConfig   = "true"
    }
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sonarr"
      }
    }

    template {
      metadata {
        labels = {
          app = "sonarr"
        }
      }

      spec {
        container {
          image = "linuxserver/sonarr"
          name  = "sonarr"

          port {
            container_port = 8989
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
            sub_path   = "sonarr/config"
            name = "config-vol"
          }
          volume_mount {
            mount_path = "/tv"
            sub_path = "TVShows"
            name = "media-vol"
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

resource "kubernetes_service" "sonarr" {
  metadata {
    name = "sonarr"
    namespace = kubernetes_namespace.media.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.sonarr.spec.0.template.0.metadata.0.labels.app
    }
    
    port {
      port        = 8989
      target_port = 8989
    }

    type = "ClusterIP"
  }
}