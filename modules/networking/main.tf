# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

# VPC Network and Subnets
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = ">= 9.0.0"

  project_id   = var.project_id
  network_name = var.vpc_name
  routing_mode = "REGIONAL"
  description  = ""

  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = var.primary_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = "true"
    },
    {
      subnet_name   = "${var.name_prefix}-proxy-subnet"
      subnet_ip     = var.proxy_subnet_cidr
      subnet_region = var.region
      purpose       = "REGIONAL_MANAGED_PROXY"
      role          = "ACTIVE"
    },
    {
      subnet_name   = "${var.name_prefix}-psc-subnet"
      subnet_ip     = var.psc_subnet_cidr
      subnet_region = var.region
      purpose       = "PRIVATE_SERVICE_CONNECT"
    }
  ]
}

resource "google_compute_router" "nat_router" {
  name    = "${var.name_prefix}-nat-router"
  project = var.project_id
  network = module.vpc.network_self_link
  region  = var.region
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.name_prefix}-nat-gateway"
  project                            = var.project_id
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Combined MCP and PSC Interface private DNS zone — attached to the VPC so
# workloads resolve internally, and also available for DNS peering (e.g. for
# Agent Engine) if needed.
module "mcp_internal_dns_zone" {
  count   = var.mcp_internal_dns_zone != null ? 1 : 0
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 7.0"

  project_id  = var.project_id
  type        = "private"
  name        = var.mcp_internal_dns_zone.name
  domain      = var.mcp_internal_dns_zone.domain
  description = "MCP servers internal private DNS zone"

  private_visibility_config_networks = [
    module.vpc.network_self_link
  ]
}

# PSC Interface — dedicated regular subnet for network attachment
resource "google_compute_subnetwork" "psc_interface" {
  project                  = var.project_id
  name                     = "${var.name_prefix}-psc-interface-subnet"
  region                   = var.region
  network                  = module.vpc.network_self_link
  ip_cidr_range            = var.psc_interface_subnet_cidr
  private_ip_google_access = true
}

# PSC Interface — network attachment with automatic acceptance
resource "google_compute_network_attachment" "psc_interface" {
  project               = var.project_id
  name                  = "${var.name_prefix}-psc-interface-attachment"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = [google_compute_subnetwork.psc_interface.self_link]
}

# PSC Interface — firewall rule allowing ingress from PSC-I subnet
resource "google_compute_firewall" "psc_interface_allow" {
  project       = var.project_id
  name          = "${var.name_prefix}-allow-psc-interface"
  network       = module.vpc.network_self_link
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [var.psc_interface_subnet_cidr]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
  allow {
    protocol = "icmp"
  }
}

# Agent Gateway — dedicated regular subnet that hosts both the Agent Gateway
# PSC-Interface network attachment and the relocated MCP internal LB VIP.
resource "google_compute_subnetwork" "agent_gateway" {
  project       = var.project_id
  name          = "${var.name_prefix}-agent-gateway-subnet"
  region        = var.region
  network       = module.vpc.network_self_link
  ip_cidr_range = var.agent_gateway_subnet_cidr
}

# PSC Interface — private DNS zone for DNS peering (only if different from MCP zone)
module "psc_interface_dns_zone" {
  count   = var.psc_interface_dns_zone != null && (var.mcp_internal_dns_zone == null || var.psc_interface_dns_zone.name != var.mcp_internal_dns_zone.name) ? 1 : 0
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 7.0"

  project_id  = var.project_id
  type        = "private"
  name        = var.psc_interface_dns_zone.name
  domain      = var.psc_interface_dns_zone.domain
  description = "PSC Interface private DNS zone for peering"

  private_visibility_config_networks = []
}
