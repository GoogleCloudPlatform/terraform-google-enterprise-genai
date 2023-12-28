locals {
  github_repository  = replace(var.github_remote_uri, "https://", "")
  composer_node_use4 = "172.16.8.0/22"
  composer_node_usc1 = "172.17.8.0/22"

  # secondary
  pods_use4     = "172.18.0.0/16"
  services_use4 = "172.16.12.0/22"

  pods_usc1     = "172.19.0.0/16"
  services_usc1 = "172.17.12.0/22"

  # composer specific
  composer_master_use4 = "192.168.0.0/28"
  composer_master_usc1 = "192.168.1.0/28"

  composer_webserver_use4 = "192.168.2.0/29"
  composer_webserver_usc1 = "192.168.3.0/29"

  private_service_connect_ip = "10.116.46.2"

  env_code     = substr(var.environment, 0, 1)
  keyring_name = "sample-keyring"
  name_var     = format("%s-%s", local.env_code, var.name)
  labels = merge(
    var.labels,
    {
      "environment" = var.environment
      "env_code"    = local.env_code
    }
  )
  region_short_code = {
    "us-central1" = "usc1"
    "us-east4"    = "use4"
  }
  zones = {
    "us-central1" = ["a", "b", "c"]
    "us-east4"    = ["a", "b", "c"]
  }
  network_name                  = var.region == "us-central1" ? "composer-vpc-usc1" : "composer-vpc-use4"
  subnetwork                    = var.region == "us-central1" ? "composer-primary-usc1" : "composer-primary-use4"
  services_secondary_range_name = var.region == "us-central1" ? "composer-services-primary-usc1" : "composer-services-primary-use4"
  cluster_secondary_range_name  = var.region == "us-central1" ? "pods-primary-usc1" : "pods-primary-use4"

  tags = var.region == "us-central1" ? ["composer-usc1"] : ["composer-use4"]
}
