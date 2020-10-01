provider "kubernetes" {
}

resource "kubernetes_namespace" "techunter" {
  metadata {
    name = "techunter"
  }
}
