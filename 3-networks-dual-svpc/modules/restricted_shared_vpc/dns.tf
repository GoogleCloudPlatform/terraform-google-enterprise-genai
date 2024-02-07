/**
 * Copyright 2021 Google LLC
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


data "google_netblock_ip_ranges" "private_apis" {
  range_type = "private-googleapis"
}

locals {
  cidr_block = data.google_netblock_ip_ranges.private_apis.cidr_blocks_ipv4[0]

  cidr_prefix = split("/", local.cidr_block)[1]

  # Calculate the number of available IP addresses
  ip_count = range(pow(2, 32 - local.cidr_prefix))

  # Generate a list of IP addresses
  google_private_ip_addresses = [for i in range(pow(2, 32 - local.cidr_prefix)) : cidrhost(local.cidr_block, i)]
}

/******************************************
  Default DNS Policy
 *****************************************/

resource "google_dns_policy" "default_policy" {
  project                   = var.project_id
  name                      = "dp-${var.environment_code}-shared-restricted-default-policy"
  enable_inbound_forwarding = var.dns_enable_inbound_forwarding
  enable_logging            = var.dns_enable_logging
  networks {
    network_url = module.main.network_self_link
  }
}

/******************************************
 Creates DNS Peering to DNS HUB
*****************************************/
data "google_compute_network" "vpc_dns_hub" {
  name    = "vpc-c-dns-hub"
  project = var.dns_hub_project_id
}

module "peering_zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 5.0"

  project_id  = var.project_id
  type        = "peering"
  name        = "dz-${var.environment_code}-shared-restricted-to-dns-hub"
  domain      = var.domain
  description = "Private DNS peering zone."

  private_visibility_config_networks = [
    module.main.network_self_link
  ]
  target_network = data.google_compute_network.vpc_dns_hub.self_link
}

/***********************************************
  Notebooks DNS Zone & records.
 ***********************************************/

module "notebooks" {
  count       = var.environment_code == "d" ? 1 : 0
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-restricted-notebooks"
  domain      = "notebooks.cloud.google.com."
  description = "Private DNS zone to configure notebooks - cloud.google.com"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["notebooks.cloud.google.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.private_service_connect_ip]
    },
  ]
}

module "notebooks-googleusercontent" {
  count       = var.environment_code == "d" ? 1 : 0
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-restricted-notebooks-googleusercontent"
  domain      = "notebooks.googleusercontent.com."
  description = "Private DNS zone to configure notebooks - googleusercontent.com"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["notebooks.googleusercontent.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.private_service_connect_ip]
    },
  ]
}


module "kernels-googleusercontent" {
  count       = var.environment_code == "d" ? 1 : 0
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${var.environment_code}-shared-restricted-kernels-googleusercontent"
  domain      = "kernels.googleusercontent.com."
  description = "Private DNS zone to configure remote kernels for workbench"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["kernels.googleusercontent.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.google_private_ip_addresses
    },
  ]
}
