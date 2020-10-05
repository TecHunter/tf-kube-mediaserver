resource "kubernetes_namespace" "route53-updater" {
  metadata {
    name = "route53-updater"
  }
}


resource "kubernetes_secret" "route53-aws" {
  metadata {
    name      = "aws-secret"
    namespace = kubernetes_namespace.route53-updater.metadata.0.name
  }

  data = {
    aws-access-key-id = base64encode(var.route53-updater.id)
    aws-access-secret = base64encode(var.route53-updater.secret)
  }

}

resource "kubernetes_deployment" "route53-updater" {
  metadata {
    name = "route53-updater"
    labels = {
      app = "route53-updater"
    }
    namespace = kubernetes_namespace.route53-updater.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "route53-updater"
      }
    }

    template {
      metadata {
        labels = {
          app = "route53-updater"
        }
      }

      spec {
        container {
          image = "techunter/aws-dns-update"
          name  = "dns-update"

          env {
            name  = "AWS_ZONE_ID"
            value = data.aws_route53_zone.selected.zone_id
          }

          env {
            name  = "DNS_FQDN"
            value = "ix.${var.domain}"
          }

          env {
            name  = "DNS_QUERY_INTERVAL"
            value = "18000"
          }


          env {
            name = "AWS_ID"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.route53-aws.metadata.0.name
                key      = "aws-access-key-id"
                optional = false
              }
            }
          }

          env {
            name = "AWS_KEY"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.route53-aws.metadata.0.name
                key      = "aws-access-secret"
                optional = false
              }
            }
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "200Mi"
            }
            requests {
              cpu    = "150m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
