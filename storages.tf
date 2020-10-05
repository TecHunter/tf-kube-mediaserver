
resource "kubernetes_storage_class" "local-storage" {
  metadata {
    name = "local-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  #volume_binding_mode = "WaitForFirstConsumer"
}


resource "kubernetes_persistent_volume" "tank-config" {
  metadata {
    name = "tank-config"
  }

  spec {
    capacity = {
      storage = "200Gi"
    }
    storage_class_name = kubernetes_storage_class.local-storage.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["ix.techunter.io"]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/tank/docker/_config"
      }
    }
  }
}


resource "kubernetes_persistent_volume" "tank-download" {
  metadata {
    name = "tank-download"
  }

  spec {
    capacity = {
      storage = "1000Gi"
    }
    storage_class_name = kubernetes_storage_class.local-storage.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["ix.techunter.io"]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/tank/download"
      }
    }
  }
}


resource "kubernetes_persistent_volume" "tank-media" {
  metadata {
    name = "tank-media"
  }

  spec {
    capacity = {
      storage = "8000Gi"
    }
    storage_class_name = kubernetes_storage_class.local-storage.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["ix.techunter.io"]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/tank/media"
      }
    }
  }
}



