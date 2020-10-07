
resource "helm_release" "ingress" {
  name              = "ingress-nginx"
  chart             = "ingress-nginx"
  repository        = "https://kubernetes.github.io/ingress-nginx"
  namespace         = "ingress-nginx"
  dependency_update = true
  create_namespace  = true
}

data "kubernetes_service_account" "ingress" {
  depends_on = [helm_release.ingress]
  metadata {
    name      = "ingress-nginx"
    namespace = "ingress-nginx"
  }
}


resource "aws_iam_user" "cluster" {
  name = "k8s-r53-user"
}


resource "aws_iam_user" "ingress" {
  name = "ingress"
}

resource "aws_iam_access_key" "ingress" {
  user = aws_iam_user.ingress.name
}


data "aws_iam_policy_document" "assume-role" {
  statement {
    actions = [
      "iam:ListRoles",
      "sts:AssumeRole"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}


resource "aws_iam_policy" "assume-role" {
  name        = "allow_assume_role"
  path        = "/"
  description = "K8S policy assuming roles"

  policy = data.aws_iam_policy_document.assume-role.json
}

resource "aws_iam_user_policy_attachment" "assume_role" {
  user       = aws_iam_user.cluster.name
  policy_arn = aws_iam_policy.assume-role.arn
}

###################

data "aws_iam_policy_document" "ingress-route53-policy" {
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ingress-route53" {
  name        = "ingress-route53"
  path        = "/"
  description = "Route 53 policy for ingress-nginx"

  policy = data.aws_iam_policy_document.ingress-route53-policy.json
}

data "aws_iam_policy_document" "role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "cluster" {
  name = "k8s-role"

  assume_role_policy = data.aws_iam_policy_document.role_trust.json
}

resource "aws_iam_access_key" "cluster" {
  user = aws_iam_user.cluster.name
}



# https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md

resource "kubernetes_deployment" "external-dns" {
  timeouts {
    create = "1m"
  }
  metadata {
    name = "external-dns"
    labels = {
      app = "external-dns"
    }
    namespace = "ingress-nginx"
  }

  spec {
    strategy {
      type = "Recreate"
    }
    replicas = 1

    selector {
      match_labels = {
        app = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }

      spec {
        container {

          name = "external-dns"
          # https://github.com/kubernetes-sigs/external-dns/releases
          image = "k8s.gcr.io/external-dns/external-dns:v0.7.4"
          args = [
            "--source=service",
            "--source=ingress",
            "--domain-filter=${var.domain}", # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
            "--provider=aws",
            "--aws-assume-role=${aws_iam_role.cluster.arn}",
            "--policy=upsert-only", # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
            #"--aws-zone-type=public" # only look at public hosted zones (valid values are public, private or no value for both)
            "--registry=txt",
            "--txt-owner-id=${data.aws_route53_zone.selected.zone_id}"
          ]
        }
      }
    }
  }
}
