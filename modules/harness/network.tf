/**
 * Copyright 2026 Google LLC
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
  network_name               = "ml-vpc"
  restricted_googleapis_cidr = "199.36.153.4/30"
  subnet_ip                  = "10.0.32.0/28"

  private_service_range_name = "ml-private-service-range"
  private_service_cidr       = "10.24.192.0/24"
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 18.0"

  project_id                             = module.machine_learning_project.project_id
  network_name                           = local.network_name
  shared_vpc_host                        = "false"
  delete_default_internet_gateway_routes = "true"

  auto_create_subnetworks = "false"

  subnets = [
    {
      subnet_name           = "sb-restricted-${var.default_region}"
      subnet_ip             = local.subnet_ip
      subnet_region         = var.default_region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "restricted subnet for machine learnig workloads."
    }
  ]

  routes = [{
    name              = "rt-${local.network_name}-1000-egress-internet-default"
    description       = "Tag based route through IGW to access internet"
    destination_range = "0.0.0.0/0"
    tags              = ["egress-internet"]
    next_hop_internet = "true"
    priority          = "1000"
    },
    {
      name              = "rt-${local.network_name}-1000-all-default-windows-kms"
      description       = "Route through IGW to allow Windows KMS activation for GCP."
      destination_range = "35.190.247.13/32"
      next_hop_internet = "true"
      priority          = "1000"
  }]
}

/******************************************
  Cloud NAT & Router
*****************************************/

resource "google_compute_router" "nat_router" {
  name    = "router-${local.network_name}-${var.default_region}"
  project = module.machine_learning_project.project_id
  region  = var.default_region
  network = module.network.network_self_link

  bgp {
    asn = var.nat_bgp_asn
  }
}

resource "google_compute_address" "nat_external_addresses" {
  project = module.machine_learning_project.project_id
  name    = "ca-${local.network_name}-${var.default_region}"
  region  = var.default_region
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-${local.network_name}-${var.default_region}"
  project                            = module.machine_learning_project.project_id
  router                             = google_compute_router.nat_router.name
  region                             = var.default_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_external_addresses.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}
