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
  is_self_signed = var.tls_mode == "self_signed"
  is_public_ca   = var.tls_mode == "public_ca"

  # Public CA / Certificate Manager calculations
  domain_name_clean = var.dns_zone_domain != null ? trimsuffix(var.dns_zone_domain, ".") : ""
  domain_auth_name  = var.dns_zone_domain != null ? replace(local.domain_name_clean, ".", "-") : ""
  wildcard_domain   = var.dns_zone_domain != null ? "*.${local.domain_name_clean}" : ""

  internal_domain        = var.dns_zone_domain != null ? "internal.${local.domain_name_clean}" : ""
  internal_wildcard      = var.dns_zone_domain != null ? "*.${local.internal_domain}" : ""
  internal_auth_name     = "internal-auth"
  internal_auth_regional = "${local.internal_auth_name}-regional"

  mcp_domain        = var.dns_zone_domain != null ? "mcp.${local.domain_name_clean}" : ""
  mcp_wildcard      = var.dns_zone_domain != null ? "*.${local.mcp_domain}" : ""
  mcp_auth_regional = "mcp-auth-regional"

  internal_regional_domains = [
    local.internal_domain,
    local.internal_wildcard,
    local.mcp_domain,
    local.mcp_wildcard,
  ]
  internal_regional_san_hash = substr(sha256(jsonencode(local.internal_regional_domains)), 0, 8)

  # Self-signed SAN defaults
  effective_mcp_dns_names = length(var.mcp_dns_names) > 0 ? var.mcp_dns_names : (
    var.dns_zone_domain != null ? [
      "mcp.${local.domain_name_clean}",
      "*.mcp.${local.domain_name_clean}",
      "*.${local.domain_name_clean}"
      ] : [
      "mcp.internal",
      "*.mcp.internal",
      "*.internal"
    ]
  )

  mcp_fullchain = local.is_self_signed ? "${tls_locally_signed_cert.mcp[0].cert_pem}${tls_self_signed_cert.ca[0].cert_pem}" : ""
}

# ==============================================================================
# MODE: Public CA (Google Certificate Manager with DNS-01 authorizations)
# ==============================================================================

# Regional DNS Authorizations
resource "google_certificate_manager_dns_authorization" "regional" {
  for_each = local.is_public_ca && var.dns_zone_domain != null ? {
    "${local.domain_auth_name}-regional" = local.domain_name_clean
    (local.internal_auth_regional)       = local.internal_domain
    (local.mcp_auth_regional)            = local.mcp_domain
  } : {}

  project     = var.project_id
  name        = each.key
  location    = var.region
  domain      = each.value
  type        = "PER_PROJECT_RECORD"
  description = "Regional DNS authorization for ${each.value}"
  labels      = var.labels
}

# Regional certificate for public domain
resource "google_certificate_manager_certificate" "regional" {
  count = local.is_public_ca && var.dns_zone_domain != null ? 1 : 0

  name        = var.regional_certificate_name
  location    = var.region
  project     = var.project_id
  description = "Regional certificate for ${local.domain_name_clean} and subdomains"

  managed {
    domains = [local.domain_name_clean, local.wildcard_domain]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.regional["${local.domain_auth_name}-regional"].id
    ]
  }

  labels = var.labels
}

# Internal regional certificate
resource "google_certificate_manager_certificate" "internal_regional" {
  count = local.is_public_ca && var.dns_zone_domain != null ? 1 : 0

  name        = "${var.internal_certificate_name}-${local.internal_regional_san_hash}"
  location    = var.region
  project     = var.project_id
  description = "Regional certificate for ${join(", ", local.internal_regional_domains)}"

  managed {
    domains = local.internal_regional_domains
    dns_authorizations = [
      google_certificate_manager_dns_authorization.regional[local.internal_auth_regional].id,
      google_certificate_manager_dns_authorization.regional[local.mcp_auth_regional].id,
    ]
  }

  labels = var.labels

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# MODE: Self-Signed (Private CA & Self-Signed Regional SSL Certificate)
# ==============================================================================

resource "tls_private_key" "ca" {
  count     = local.is_self_signed ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  count           = local.is_self_signed ? 1 : 0
  private_key_pem = tls_private_key.ca[0].private_key_pem

  subject {
    common_name = var.ca_common_name
  }

  is_ca_certificate     = true
  validity_period_hours = var.ca_validity_period_hours
  early_renewal_hours   = 8760 # 1 year before expiry

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "tls_private_key" "mcp" {
  count       = local.is_self_signed ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "mcp" {
  count           = local.is_self_signed ? 1 : 0
  private_key_pem = tls_private_key.mcp[0].private_key_pem

  subject {
    common_name = local.effective_mcp_dns_names[0]
  }

  dns_names = local.effective_mcp_dns_names
}

resource "tls_locally_signed_cert" "mcp" {
  count              = local.is_self_signed ? 1 : 0
  cert_request_pem   = tls_cert_request.mcp[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = 720 # 30 days before expiry

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "google_compute_region_ssl_certificate" "self_signed" {
  count       = local.is_self_signed ? 1 : 0
  project     = var.project_id
  region      = var.region
  name_prefix = "${var.name_prefix}-mcp-cert-"
  private_key = tls_private_key.mcp[0].private_key_pem
  certificate = local.mcp_fullchain

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_certificate_manager_trust_config" "self_signed" {
  count       = local.is_self_signed ? 1 : 0
  project     = var.project_id
  name        = "${var.name_prefix}-mcp-trust"
  location    = var.region
  description = "TrustConfig for Agent Gateway to trust the internal MCP CA"

  trust_stores {
    trust_anchors {
      pem_certificate = tls_self_signed_cert.ca[0].cert_pem
    }
  }
}
