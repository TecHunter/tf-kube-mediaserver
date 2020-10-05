resource "kubernetes_persistent_volume" "tank-config" {
  metadata {
    name = "tank-config"
  }

  spec {
    capacity = {
      storage = "200Gi"
    }
    storage_class_name = "microk8s-hostpath"
    persistent_volume_reclaim_policy = "Retain"
    access_modes       = ["ReadWriteOnce"]
   
    persistent_volume_source {
      host_path {
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
    storage_class_name = "microk8s-hostpath"
    persistent_volume_reclaim_policy = "Retain"
    access_modes       = ["ReadWriteOnce"]
    
    persistent_volume_source {
      host_path {
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
    storage_class_name = "microk8s-hostpath"
    persistent_volume_reclaim_policy = "Retain"
    access_modes       = ["ReadWriteOnce"]
    
    persistent_volume_source {
      host_path {
        path = "/tank/media"
      }
    }
  }
}



