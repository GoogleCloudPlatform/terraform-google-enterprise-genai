/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
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

  sa_name = format("%s-%s", data.google_project.project.labels.env_code, var.name)

  labels = merge(
    var.labels,
    {
      "environment" = data.google_project.project.labels.environment
      "env_code"    = data.google_project.project.labels.env_code
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

  service_agents = [
    "artifactregistry.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com"
  ]

  tags = var.region == "us-central1" ? ["composer-usc1"] : ["composer-use4"]

  github_repository = replace(var.github_remote_uri, "https://", "")
}
