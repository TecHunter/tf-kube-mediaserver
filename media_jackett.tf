
resource "kubernetes_deployment" "jackett" {
  metadata {
    name = "jackett"
    labels = {
      app         = "jackett"
      hasDownload = "true"
      hasConfig   = "true"
    }
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "jackett"
      }
    }

    template {
      metadata {
        labels = {
          app = "jackett"
        }
      }

      spec {
        container {
          image = "linuxserver/jackett"
          name  = "jacket"

          port {
            container_port = 9117
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
            sub_path   = "jackett/config"
            name = "config-vol"
          }
          volume_mount {
            mount_path = "/downloads"
            name = "download-vol"
          }
        }
        volume {
          name = "config-vol"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.tank-config-claim.metadata.0.name
          }
        }
        volume {
          name = "download-vol"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.tank-download-claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "jackett" {
  metadata {
    name = "jackett"
    namespace = kubernetes_namespace.media.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.jackett.spec.0.template.0.metadata.0.labels.app
    }
    
    port {
      port        = 9117
      target_port = 9117
    }

    type = "ClusterIP"
  }
}