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

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional certificates"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for certificate resource names"
  type        = string
  default     = "mcp"
}

variable "tls_mode" {
  description = "TLS certificate provisioning mode: 'self_signed' (default, uses private CA + TrustConfig) or 'public_ca' (uses Certificate Manager + DNS-01 authorizations with public domain)."
  type        = string
  default     = "self_signed"
  validation {
    condition     = contains(["self_signed", "public_ca"], var.tls_mode)
    error_message = "tls_mode must be either 'self_signed' or 'public_ca'."
  }
}

# ------------------------------------------------------------------------------
# Self-Signed Mode Configurations
# ------------------------------------------------------------------------------
variable "ca_common_name" {
  description = "Common Name (CN) for the self-signed Root CA"
  type        = string
  default     = "Enterprise MCP Root CA"
}

variable "mcp_dns_names" {
  description = "List of DNS Subject Alternative Names (SANs) for the self-signed MCP server certificate"
  type        = list(string)
  default     = []
}

variable "ca_validity_period_hours" {
  description = "Validity period in hours for the self-signed Root CA (default 10 years)"
  type        = number
  default     = 87600
}

variable "validity_period_hours" {
  description = "Validity period in hours for the MCP server certificate (default ~397 days)"
  type        = number
  default     = 9528
}

# ------------------------------------------------------------------------------
# Public CA (Certificate Manager) Configurations
# ------------------------------------------------------------------------------
variable "dns_zone_domain" {
  description = "DNS zone domain (must end with dot, e.g., 'example.com.'). Required when tls_mode = 'public_ca'."
  type        = string
  default     = null
  validation {
    condition     = var.dns_zone_domain == null || can(regex("[.]$", var.dns_zone_domain))
    error_message = "dns_zone_domain must end with a dot (e.g., 'example.com.') or be null"
  }
}

variable "labels" {
  description = "Labels to apply to certificate resources"
  type        = map(string)
  default     = {}
}

variable "regional_certificate_name" {
  description = "Name for the regional certificate (public domain)"
  type        = string
  default     = "main-certificate-regional"
}

variable "internal_certificate_name" {
  description = "Name for the internal certificate covering base domain and wildcard (private endpoints)"
  type        = string
  default     = "internal-certificate-regional"
}
