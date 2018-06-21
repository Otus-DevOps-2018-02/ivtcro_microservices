terraform {
  backend "gcs" {
    bucket = "reddit-hosts-microservices"
    prefix = "terraform/state"
  }
}
