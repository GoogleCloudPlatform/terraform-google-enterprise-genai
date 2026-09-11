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

# Regional Internal Application Load Balancer fronting all MCP Cloud Run
# services. A single Serverless NEG with a URL mask of
# "<service>.<dns_domain_no_dot>" auto-routes by Host header to the Cloud Run
# service whose name matches <service>. Adding a new MCP service later only
# requires deploying it (with a matching Cloud Run name) and inserting one
# DNS A record — no LB resource changes.

locals {
  dns_domain_no_dot = trimsuffix(var.dns_domain, ".")
  lb_name           = "${var.name_prefix}-mcp-ilb"
}

# Allocate the LB VIP in the primary subnet unless the caller passed one in.
resource "google_compute_address" "lb" {
  count = var.create_address ? 1 : 0

  project      = var.project_id
  name         = "${local.lb_name}-ip"
  description  = "Internal IP for the MCP services Application LB"
  region       = var.region
  subnetwork   = var.subnet_self_link
  address_type = "INTERNAL"
}

# Single Serverless NEG with URL mask: the LB extracts <service> from the Host
# header (e.g. legacy-dms.mcp-server.internal) and routes to the Cloud Run
# service named <service> in this region.
resource "google_compute_region_network_endpoint_group" "mcp" {
  project               = var.project_id
  name                  = "${local.lb_name}-neg-${substr(sha256(local.dns_domain_no_dot), 0, 6)}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    url_mask = "<service>.${local.dns_domain_no_dot}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_backend_service" "mcp" {
  project               = var.project_id
  name                  = "${local.lb_name}-backend"
  region                = var.region
  protocol              = "HTTPS"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group           = google_compute_region_network_endpoint_group.mcp.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_region_url_map" "mcp" {
  project         = var.project_id
  name            = "${local.lb_name}-urlmap"
  region          = var.region
  default_service = google_compute_region_backend_service.mcp.id
}

resource "google_compute_region_target_https_proxy" "mcp" {
  project                          = var.project_id
  name                             = "${local.lb_name}-https-proxy"
  region                           = var.region
  url_map                          = google_compute_region_url_map.mcp.id
  certificate_manager_certificates = [var.ssl_certificate_id]
}

# Subnet READY != regional Envoy ready. NEG/backend/urlmap/proxy still create
# during this wait (only the forwarding rule is gated).
resource "time_sleep" "wait_proxy_only_envoy" {
  create_duration = var.proxy_only_settle_duration

  triggers = {
    network      = var.network_self_link
    proxy_subnet = var.proxy_subnet_self_link
  }
}

resource "google_compute_forwarding_rule" "mcp" {
  project               = var.project_id
  name                  = local.lb_name
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = var.network_self_link
  subnetwork            = var.forwarding_rule_subnet_self_link != null ? var.forwarding_rule_subnet_self_link : var.subnet_self_link
  ip_address            = var.internal_ip_address != null ? var.internal_ip_address : google_compute_address.lb[0].address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.mcp.id
  labels                = var.labels

  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }

  depends_on = [time_sleep.wait_proxy_only_envoy]
}
