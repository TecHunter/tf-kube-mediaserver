variable "domain" {
  default = "techunter.io"
  type    = string
}

variable "aws" {
  default = {
    id     = "IAMUSER"
    secret = "IAMPASS"
  }
}

variable "route53-updater" {
  default = {
    id     = "IAMUSER_FOR_ROUTE53"
    secret = "IAMPASS_FOR_ROUTE53"
  }
}

variable "nextcloud" {
  description = "NextCloud params"
  default = {
    size = "100Gi"
    admin = {
      username = "admin"
      password = "password"
    }
  }
}

variable "cert-issuer" {
  description = "Issuer params"
  default = {
    email = "a.baschenis@techunter.io"
  }
}

variable "torrent" {
  description = "Ports to listen to"
  default     = { start = 60881, end = 60891 }
}

variable "plex_claim" {
  description = "plex claim for Plex PASS"
}

variable "plex_ports" {
  default = [1900, 3005, 5353,8324,32410,32412,32413,32414,32469]
  description = "(optional) Plex ports, leave defaults"
}