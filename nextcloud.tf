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
      storage = var.nextcloud.size
    }
    storage_class_name               = "microk8s-hostpath"
    persistent_volume_reclaim_policy = "Retain"
    access_modes                     = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
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
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "microk8s-hostpath"
    resources {
      requests = {
        storage = kubernetes_persistent_volume.nextcloud-data.spec.0.capacity.storage
      }
    }
    volume_name = kubernetes_persistent_volume.nextcloud-data.metadata.0.name
  }
}


resource "helm_release" "nextcloud" {
  name              = "nextcloud"
  chart             = "nextcloud"
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
    value = "ReadWriteOnce"
  }

  set {
    name  = "persistence.size"
    value = var.nextcloud.size
  }
}

resource "kubernetes_ingress" "nextcloud" {
  depends_on = [helm_release.nginx-ingress]
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
      host = "drive.192.168.1.200.nip.io"
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
