data "aws_route53_zone" "selected" {
  name         = "${var.domain}."
  private_zone = false
  // will provide data.aws_route53_zone.selected.zone_id
}
/*

resource "aws_acm_certificate" "default" {
  provider = aws.acm
  domain_name = var.domain
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  provider = aws.acm
  for_each = {
  for dvo in aws_acm_certificate.subdomain.domain_validation_options : dvo.domain_name => {
    name = dvo.resource_record_name
    record = dvo.resource_record_value
    type = dvo.resource_record_type
  }
  }

  records = [
    each.value.record
  ]
  ttl = 300
  name = each.value.name
  type = each.value.type
  zone_id = data.aws_route53_zone.selected.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  provider = aws.acm
  certificate_arn = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
  depends_on = [
    aws_route53_record.validation
  ]
}


resource "aws_acmpca_certificate_authority" "default" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = var.domain
    }
  }

  permanent_deletion_time_in_days = 7
}
resource "kubernetes_namespace" "aws_pca" {
  metadata {
    name = "awspca-issuer-system"
  }
}

resource "kubernetes_secret" "aws" {
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_deployment.aws_pca.metadata.0.name
  }

  data = {
    accesskey = base64encode(var.aws_pca.accesskey)
    secretkey = base64encode(var.aws_pca.secretkey)
    region    = base64encode(var.aws_pca.region)
    arn       = base64encode(var.aws_pca.arn)
  }

}
*/