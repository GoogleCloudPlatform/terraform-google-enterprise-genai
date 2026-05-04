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
      subnet_name           = "sb-restricted-${var.region}"
      subnet_ip             = local.subnet_ip
      subnet_region         = var.region
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
