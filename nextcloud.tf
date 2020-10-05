resource "kubernetes_namespace" "nextcloud" {
  metadata {
    name = "nextcloud"
  }
}


resource "kubernetes_persistent_volume" "nextcloud-data" {
  metadata {
    name = "nextcloud-data"
  }

  spec {
    capacity = {
      storage = "100Gi"
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
        path = "/tank/media/files"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nextcloud-claim" {
  metadata {
    name      = "nextcloud-claim"
    namespace = kubernetes_namespace.nextcloud.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.local-storage.metadata.0.name
    resources {
      requests = {
        storage = var.nextcloud.size
      }
    }
    volume_name = kubernetes_persistent_volume.nextcloud-data.metadata.0.name
  }
}


resource "helm_release" "nextcloud" {
  name              = "nextcloud"
  chart             = "nextcloud/nextcloud"
  repository        = "https://nextcloud.github.io/helm/"
  dependency_update = true
  namespace         = kubernetes_namespace.nextcloud.metadata[0].name

  set {
    name  = "nextcloud.host"
    value = "${aws_route53_record.nextcloud.name}.${var.domain}"
  }

  set {
    name  = "nextcloud.username"
    value = var.nextcloud.admin.username
  }

  set {
    name  = "nextcloud.password"
    value = var.nextcloud.admin.password
  }

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.nextcloud-claim.metadata.0.name
  }

  set {
    name  = "persistence.accessMode"
    value = "ReadWriteMany"
  }

  set {
    name  = "persistence.size"
    value = var.nextcloud.size
  }
}

resource "kubernetes_ingress" "nextcloud" {
  metadata {
    name      = "nextcloud-ingress"
    namespace = kubernetes_namespace.nextcloud.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class"                 = "nginx"
      "cert-manager.io/cluster-issuer"              = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
    }
  }

  spec {
    backend {
      service_name = "nextcloud"
      service_port = 8080
    }

    rule {
      host = "drive.techunter.io"
      http {
        path {
          backend {
            service_name = "nextcloud"
            service_port = 8080
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

resource "aws_route53_record" "nextcloud" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "drive"
  type    = "CNAME"
  ttl     = "300"

  records = ["ix.${var.domain}"]

  allow_overwrite = true
}
