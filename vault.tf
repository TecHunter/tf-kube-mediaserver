/*resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  name      = "vault"
  chart     = "hashicorp/vault"
  namespace = kubernetes_namespace.vault.metadata[0].name
  //repository = "https://helm.releases.hashicorp.com"
}
*/