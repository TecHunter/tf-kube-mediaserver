resource "helm_release" "cert-manager" {
  name              = "cert-manager"
  chart             = "cert-manager"
  repository        = "https://charts.jetstack.io"
  namespace         = "cert-manager"
  dependency_update = true
  create_namespace  = true

  set {
    name  = "installCRDs"
    value = true
  }
}

data "kubernetes_namespace" "cert-manager"{
  depends_on = [helm_release.cert-manager]
  metadata {
    name = "cert-manager"
  }
  
}

resource "aws_iam_user" "cert-manager" {
  name = "cert-manager"
}

resource "aws_iam_access_key" "cert-manager" {
  user = aws_iam_user.cert-manager.name
}

resource "aws_iam_policy" "cert-manager-route53" {
  name        = "cert-manager-route53"
  path        = "/"
  description = "Route 53 policy for cert-manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "cert-manager" {
  user       = aws_iam_user.cert-manager.name
  policy_arn = aws_iam_policy.cert-manager-route53.arn
}


output "cert-manager-creds-id" {
  value = aws_iam_access_key.cert-manager.id
}
output "cert-manager-creds-key" {
  value     = aws_iam_access_key.cert-manager.encrypted_secret
  sensitive = true
}

resource "kubernetes_secret" "cert-manager" {
  metadata {
    name      = "cert-manager-creds"
    namespace = data.kubernetes_namespace.cert-manager.metadata.0.name
  }

  data = {
    aws-access-key-id = base64encode(aws_iam_access_key.cert-manager.id)
    aws-access-secret = aws_iam_access_key.cert-manager.encrypted_secret
  }

}

data "template_file" "issuer-prod" {
  template = templatefile("${path.module}/issuer-prod.yaml",
    {
      region      = var.route53-updater.region
      domain      = var.domain
      zone_id     = data.aws_route53_zone.selected.zone_id
      accessKeyID = aws_iam_access_key.cert-manager.id
      secret-name = kubernetes_secret.cert-manager.metadata.0.name
      secret-key  = "aws-access-secret"
    }
  )

}

resource "null_resource" "issuer-prod" {
  depends_on = [data.kubernetes_namespace.cert-manager]
  triggers = {
    manifest_sha1 = sha1(data.template_file.issuer-prod.rendered)
  }

  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.template_file.issuer-prod.rendered}\nEOF"
  }
}
