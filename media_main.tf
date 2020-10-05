resource "kubernetes_namespace" "media" {
  metadata {
    name = "media"
  }
}

resource "kubernetes_persistent_volume_claim" "tank-config-claim" {
  metadata {
    name      = "tank-config-claim"
    namespace = kubernetes_namespace.media.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.tank-config.spec.0.capacity.storage
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "tank-media-claim" {
  metadata {
    name      = "tank-media-claim"
    namespace = kubernetes_namespace.media.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.tank-media.spec.0.capacity.storage
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "tank-download-claim" {
  metadata {
    name      = "tank-download-claim"
    namespace = kubernetes_namespace.media.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.tank-download.spec.0.capacity.storage
      }
    }
  }
}
