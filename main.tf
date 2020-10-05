terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>1.13.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>1.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
}

provider "aws" {
  region     = "eu-central-1"
  profile    = "default"
  access_key = var.aws.id
  secret_key = var.aws.secret
}
