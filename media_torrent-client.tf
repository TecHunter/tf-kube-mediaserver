
resource "kubernetes_deployment" "torrent-client" {
  metadata {
    name = "torrent-client"
    labels = {
      app         = "torrent-client"
      hasDownload = "true"
      hasConfig   = "true"
    }
    namespace = kubernetes_namespace.media.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "torrent-client"
      }
    }

    template {
      metadata {
        labels = {
          app = "torrent-client"
        }
      }

      spec {
        container {
          image = "linuxserver/qbittorrent"
          name  = "jacket"

          port {
            container_port = 8112
          }
          dynamic "port" {
            for_each = range(var.torrent.start, var.torrent.end)
            content {
              container_port = port.value
            }
          }

          dynamic "port" {
            for_each = range(var.torrent.start, var.torrent.end)
            content {
              container_port = port.value
              protocol       = "UDP"
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
            name  = "UMASK_SET"
            value = "022"
          }
          env {
            name  = "WEBUI_PORT"
            value = "8112"
          }
          volume_mount {
            mount_path = "/config"
            sub_path   = "qbittorrent/config"
            name       = kubernetes_persistent_volume_claim.tank-config-claim.metadata.0.name
          }
          volume_mount {
            mount_path = "/downloads"
            name       = kubernetes_persistent_volume_claim.tank-download-claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "torrent-client" {
  metadata {
    name = "torrent-client"
    namespace = kubernetes_namespace.media.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.torrent-client.spec.0.template.0.metadata.0.labels.app
    }
    
    port {
      port        = 8080
      target_port = 8112
    }

    type = "LoadBalancer"
  }
}