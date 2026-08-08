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

locals {
  registry_uri = "//agentregistry.googleapis.com/projects/${var.project_id}/locations/${var.region}"
}

# PSC-Interface network attachment in the dedicated co-location subnet. This is
# what the Agent Gateway egresses through to reach the customer VPC (and from
# there the MCP internal LB).
resource "google_compute_network_attachment" "agent_gateway" {
  project               = var.project_id
  name                  = "${var.name}-na"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = [var.agent_gateway_subnet_self_link]
}

# Allow the gateway tenant's PSC-I NIC (sourcing from the dedicated subnet) to
# reach the MCP internal LB on its front-end port.
resource "google_compute_firewall" "agent_gateway_psc_i" {
  project       = var.project_id
  name          = "${var.name}-allow-psc-i"
  network       = var.network_self_link
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [var.agent_gateway_subnet_cidr]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.mcp_lb_target_port)]
  }
}

# The Agent Gateway itself. Google-managed, AGENT_TO_ANYWHERE.
resource "google_network_services_agent_gateway" "this" {
  project  = var.project_id
  name     = var.name
  location = var.region

  google_managed {
    governed_access_path = "AGENT_TO_ANYWHERE"
  }

  registries = [local.registry_uri]

  network_config {
    egress {
      network_attachment = google_compute_network_attachment.agent_gateway.id
    }

    dynamic "dns_peering_config" {
      for_each = try(length(var.dns_peering_config.domains), 0) > 0 ? [var.dns_peering_config] : []
      content {
        domains        = dns_peering_config.value.domains
        target_project = dns_peering_config.value.target_project
        target_network = trimprefix(dns_peering_config.value.target_network, "https://www.googleapis.com/compute/v1/"
        )
      }
    }
  }
}

resource "time_sleep" "wait_for_gateway" {
  depends_on      = [google_network_services_agent_gateway.this]
  create_duration = "30s"
}

resource "google_network_services_authz_extension" "iap" {
  provider = google-beta

  project   = var.project_id
  name      = "${var.name}-iap-authz"
  location  = var.region
  service   = "iap.googleapis.com"
  timeout   = var.authz_extension_timeout
  fail_open = var.authz_extension_fail_open

  metadata = merge(
    {
      iapPolicyVersion = "V1"
    },
    var.iap_iam_enforcement_mode != null ? {
      iamEnforcementMode = var.iap_iam_enforcement_mode
    } : {}
  )
}

resource "google_network_services_authz_extension" "model_armor" {
  count    = var.enable_model_armor ? 1 : 0
  provider = google-beta

  project  = var.project_id
  name     = "${var.name}-ma-authz"
  location = var.region
  service  = "modelarmor.${var.region}.rep.googleapis.com"
  timeout  = var.authz_extension_timeout

  metadata = {
    "model_armor_settings" = jsonencode([{
      request_template_id  = "projects/${var.project_id}/locations/${var.region}/templates/${var.model_armor_request_template_id}"
      response_template_id = "projects/${var.project_id}/locations/${var.region}/templates/${var.model_armor_response_template_id}"
    }])
  }

  fail_open = var.authz_extension_fail_open

  lifecycle {
    precondition {
      condition     = var.model_armor_request_template_id != null && var.model_armor_response_template_id != null
      error_message = "Both model_armor_request_template_id and model_armor_response_template_id are required when enable_model_armor is true."
    }
  }
}

resource "google_network_security_authz_policy" "iap" {
  provider = google-beta

  project        = var.project_id
  name           = "${var.name}-iap-policy"
  location       = var.region
  policy_profile = "REQUEST_AUTHZ"
  action         = "CUSTOM"

  target {
    resources = [google_network_services_agent_gateway.this.id]
  }

  custom_provider {
    authz_extension {
      resources = [google_network_services_authz_extension.iap.id]
    }
  }

  depends_on = [time_sleep.wait_for_gateway]
}

resource "google_network_security_authz_policy" "model_armor" {
  count    = var.enable_model_armor ? 1 : 0
  provider = google-beta

  project        = var.project_id
  name           = "${var.name}-ma-policy"
  location       = var.region
  policy_profile = "CONTENT_AUTHZ"
  action         = "CUSTOM"

  target {
    resources = [google_network_services_agent_gateway.this.id]
  }

  custom_provider {
    authz_extension {
      resources = [google_network_services_authz_extension.model_armor[0].id]
    }
  }

  dynamic "http_rules" {
    for_each = length(var.model_armor_authz_hosts) > 0 ? [1] : []
    content {
      to {
        operations {
          dynamic "hosts" {
            for_each = var.model_armor_authz_hosts
            content {
              exact = hosts.value
            }
          }
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_gateway, google_network_security_authz_policy.iap]
}

locals {
  service_extensions_sa_member = "serviceAccount:${google_network_services_agent_gateway.this.agent_gateway_card[0].service_extensions_service_account}"

  model_armor_sa_roles = var.enable_model_armor ? [
    "roles/modelarmor.calloutUser",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/modelarmor.user",
  ] : []
}

resource "google_project_iam_member" "service_extensions_sa" {
  for_each = toset(local.model_armor_sa_roles)

  project = var.project_id
  role    = each.value
  member  = local.service_extensions_sa_member
}
