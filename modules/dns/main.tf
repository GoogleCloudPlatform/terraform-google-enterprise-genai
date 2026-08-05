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
  # Derive internal domain from dns_zone_domain if not explicitly provided
  internal_dns_domain_computed = var.internal_dns_domain != null ? var.internal_dns_domain : (
    var.dns_zone_domain != null ? "internal.${var.dns_zone_domain}" : null
  )
}

data "google_dns_managed_zone" "dns_zone" {
  count   = var.dns_zone_domain != null ? 1 : 0
  project = var.project_id
  name    = var.dns_zone_name != null ? var.dns_zone_name : replace(trimsuffix(var.dns_zone_domain, "."), ".", "-")
}

# Certificate validation DNS records for regional certificates
resource "google_dns_record_set" "certificate_validation_regional" {
  for_each = var.dns_zone_domain != null && var.certificate_dns_authorizations_regional != null ? var.certificate_dns_authorizations_regional : {}

  project      = var.project_id
  name         = each.value.dns_resource_record[0].name
  managed_zone = data.google_dns_managed_zone.dns_zone[0].name
  type         = each.value.dns_resource_record[0].type
  ttl          = var.certificate_validation_ttl
  rrdatas      = [each.value.dns_resource_record[0].data]

  depends_on = [data.google_dns_managed_zone.dns_zone]
}

# Private DNS Zone for internal gateways
resource "google_dns_managed_zone" "internal_dns_zone" {
  count       = var.dns_zone_domain != null ? 1 : 0
  project     = var.project_id
  name        = var.internal_dns_zone_name
  dns_name    = "${trimsuffix(local.internal_dns_domain_computed, ".")}.`"
  description = "Private DNS zone for internal gateways"
  visibility  = "private"

  private_visibility_config {
    dynamic "networks" {
      for_each = var.vpc_self_links
      content {
        network_url = networks.value
      }
    }
  }
}
