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

output "ssl_certificate_id" {
  description = "ID of the SSL certificate to attach to the MCP Internal Load Balancer"
  value = (
    local.is_self_signed
    ? google_compute_region_ssl_certificate.self_signed[0].id
    : (local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.internal_regional[0].id : null)
  )
}

output "trust_config_id" {
  description = "ID of the Certificate Manager TrustConfig for Agent Gateway (null if public_ca mode)"
  value = (
    local.is_self_signed
    ? google_certificate_manager_trust_config.self_signed[0].id
    : null
  )
}

output "ca_cert_pem" {
  description = "CA root certificate PEM (null if public_ca mode)"
  value       = local.is_self_signed ? tls_self_signed_cert.ca[0].cert_pem : null
  sensitive   = false
}

# Regional Certificate Outputs (Public CA)
output "regional_certificate_id" {
  description = "ID of the regional certificate for public domain"
  value       = local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.regional[0].id : null
}

output "regional_certificate_name" {
  description = "Name of the regional certificate for public domain"
  value       = local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.regional[0].name : null
}

output "internal_certificate_id" {
  description = "ID of the internal certificate"
  value = (
    local.is_self_signed
    ? google_compute_region_ssl_certificate.self_signed[0].id
    : (local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.internal_regional[0].id : null)
  )
}

output "internal_certificate_name" {
  description = "Name of the internal certificate"
  value = (
    local.is_self_signed
    ? google_compute_region_ssl_certificate.self_signed[0].name
    : (local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.internal_regional[0].name : null)
  )
}

output "regional_dns_authorizations" {
  description = "Map of regional DNS authorizations for certificate validation"
  value       = google_certificate_manager_dns_authorization.regional
}

# Global Certificate Outputs
output "global_certificate_id" {
  description = "ID of the global certificate for public domain (null)"
  value       = null
}

output "global_dns_authorizations" {
  description = "Map of global DNS authorizations for certificate validation (empty)"
  value       = {}
}

# Combined Outputs
output "dns_authorizations" {
  description = "All DNS authorizations (regional)"
  value       = google_certificate_manager_dns_authorization.regional
}

output "certificate_ids" {
  description = "All certificate IDs in a consistent format"
  value = {
    regional = local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.regional[0].id : null
    internal = (
      local.is_self_signed
      ? google_compute_region_ssl_certificate.self_signed[0].id
      : (local.is_public_ca && var.dns_zone_domain != null ? google_certificate_manager_certificate.internal_regional[0].id : null)
    )
  }
}

output "domains_covered" {
  description = "List of domains covered by the certificates"
  value = (
    local.is_self_signed
    ? local.effective_mcp_dns_names
    : (var.dns_zone_domain != null ? [
      trimsuffix(var.dns_zone_domain, "."),
      "*.${trimsuffix(var.dns_zone_domain, ".")}",
      local.internal_domain,
      local.internal_wildcard,
      local.mcp_domain,
      local.mcp_wildcard,
    ] : [])
  )
}
