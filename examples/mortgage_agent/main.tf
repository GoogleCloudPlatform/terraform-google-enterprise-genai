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
  mcp_internal_dns_domain_or_null = (
    var.mcp_internal_dns_zone != null
    ? var.mcp_internal_dns_zone.domain
    : null
  )

  _agent_gateway_dns_peering_domains = distinct(compact(concat(
    local.mcp_internal_dns_domain_or_null != null ? [local.mcp_internal_dns_domain_or_null] : [],
    try(var.agent_gateway_dns_peering_config.domains, []),
  )))

  agent_gateway_dns_peering_config_effective = (
    length(local._agent_gateway_dns_peering_domains) == 0
    ? null
    : {
      domains        = local._agent_gateway_dns_peering_domains
      target_project = coalesce(try(var.agent_gateway_dns_peering_config.target_project, null), var.project_id)
      target_network = coalesce(try(var.agent_gateway_dns_peering_config.target_network, null), module.networking.network_self_link)
    }
  )
}

module "observability" {
  source = "../../modules/observability"

  project_id = var.project_id

  depends_on = [time_sleep.wait_enable_apis]
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  vpc_name    = var.vpc_name
  subnet_name = var.subnet_name

  primary_subnet_cidr = var.primary_subnet_cidr
  proxy_subnet_cidr   = var.proxy_subnet_cidr
  psc_subnet_cidr     = var.psc_subnet_cidr

  mcp_internal_dns_zone = var.mcp_internal_dns_zone

  psc_interface_subnet_cidr = var.psc_interface_subnet_cidr
  psc_interface_dns_zone    = var.mcp_internal_dns_zone

  agent_gateway_subnet_cidr = var.agent_gateway_subnet_cidr

  depends_on = [time_sleep.wait_enable_apis]
}

resource "google_artifact_registry_repository" "registry" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.name_prefix}-docker"
  format        = "DOCKER"
  description   = "Regional Docker repository for container images"

  depends_on = [time_sleep.wait_enable_apis]
}

resource "google_storage_bucket" "cloudbuild" {
  project                     = var.project_id
  name                        = coalesce(var.cloudbuild_bucket_name, "${var.project_id}_cloudbuild")
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [time_sleep.wait_enable_apis]
}

resource "google_storage_bucket_iam_member" "cloudbuild_compute_sa" {
  bucket = google_storage_bucket.cloudbuild.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "cloudbuild_service_agent" {
  bucket = google_storage_bucket.cloudbuild.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

module "certificates" {
  source = "../../modules/certificates"

  project_id      = var.project_id
  region          = var.region
  dns_zone_domain = var.dns_zone_domain

  depends_on = [time_sleep.wait_enable_apis]
}

module "dns" {
  count  = var.dns_zone_domain != null ? 1 : 0
  source = "../../modules/dns"

  project_id      = var.project_id
  dns_zone_domain = var.dns_zone_domain

  certificate_dns_authorizations_regional = module.certificates.regional_dns_authorizations
  vpc_self_links                          = module.networking.network_self_link
  depends_on                              = [module.networking, module.certificates]
}

module "model_armor" {
  count  = var.enable_model_armor ? 1 : 0
  source = "../../modules/model_armor"

  project_id = var.project_id
  region     = var.region

  enable_model_armor   = var.enable_model_armor
  request_template_id  = var.model_armor_request_template_id
  response_template_id = var.model_armor_response_template_id

  platform_admin_members = var.platform_admin_members

  rai_filters = var.model_armor_rai_filters

  sdp_enforcement = var.model_armor_sdp_enforcement
  pii_types       = var.model_armor_pii_types

  pi_jailbreak_enforcement      = var.model_armor_pi_jailbreak_enforcement
  pi_jailbreak_confidence_level = var.model_armor_pi_jailbreak_confidence

  malicious_uri_enforcement = var.model_armor_malicious_uri_enforcement

  enable_mcp_floor_setting = var.enable_model_armor_mcp_floor_setting

  enable_vertex_ai_integration   = var.enable_model_armor_vertex_ai
  vertex_ai_inspect_only         = var.model_armor_vertex_ai_inspect_only
  vertex_ai_enable_cloud_logging = var.model_armor_vertex_ai_cloud_logging
}


module "agent_engine" {
  source = "../../modules/agent_engine"

  project_id     = var.project_id
  project_number = var.project_number

  org_id                 = var.org_id
  platform_admin_members = var.platform_admin_members

  depends_on = [time_sleep.wait_enable_apis]
}

module "mcp_services" {
  source = "../../modules/mcp_cloud_run"

  project_id              = var.project_id
  region                  = var.region
  services                = var.mcp_services
  mcp_internal_dns_domain = local.mcp_internal_dns_domain_or_null
  invoker_sa_email        = module.agent_engine.agent_mcp_invoker_email

  depends_on = [time_sleep.wait_enable_apis, google_artifact_registry_repository.registry]
}

resource "google_compute_address" "mcp_lb_in_agent_gw_subnet" {
  project      = var.project_id
  name         = "${var.name_prefix}-mcp-ilb-ip-agw"
  region       = var.region
  subnetwork   = module.networking.agent_gateway_subnet_self_link
  address_type = "INTERNAL"
  description  = "MCP internal LB VIP relocated to the Agent Gateway co-location subnet"
}

check "agent_gateway_mcp_cert_prereqs" {
  assert {
    condition = (
      var.mcp_internal_dns_zone != null &&
      var.dns_zone_domain != null &&
      endswith(
        trimsuffix(var.mcp_internal_dns_zone.domain, "."),
        ".${trimsuffix(var.dns_zone_domain, ".")}"
      )
    )
    error_message = "mcp_internal_dns_zone.domain must be a subdomain of dns_zone_domain (e.g. dns_zone_domain = \"agw.example.com.\" + mcp_internal_dns_zone.domain = \"mcp.agw.example.com.\") so Certificate Manager can issue the cert."
  }
}

module "mcp_internal_lb" {
  source = "../../modules/mcp_internal_lb"

  project_id         = var.project_id
  region             = var.region
  name_prefix        = var.name_prefix
  network_self_link  = module.networking.network_self_link
  subnet_self_link   = module.networking.subnets_self_links["${var.region}/${var.subnet_name}"]
  dns_domain         = var.mcp_internal_dns_zone.domain
  protocol           = var.mcp_lb_protocol
  ssl_certificate_id = module.certificates.internal_certificate_id

  create_address                   = false
  internal_ip_address              = google_compute_address.mcp_lb_in_agent_gw_subnet.address
  forwarding_rule_subnet_self_link = module.networking.agent_gateway_subnet_self_link

  labels = {
    managed-by = "terraform"
    component  = "mcp-server"
  }

  depends_on = [module.mcp_services]
}

module "agent_gateway" {
  source = "../../modules/agent_gateway"

  providers = {
    google      = google
    google-beta = google-beta
  }

  project_id = var.project_id
  region     = var.region

  name                           = var.agent_gateway_name
  network_self_link              = module.networking.network_self_link
  agent_gateway_subnet_self_link = module.networking.agent_gateway_subnet_self_link
  agent_gateway_subnet_cidr      = var.agent_gateway_subnet_cidr

  mcp_lb_target_port = var.mcp_lb_protocol == "HTTPS" ? 443 : 80

  enable_model_armor               = var.enable_model_armor
  model_armor_request_template_id  = var.enable_model_armor ? module.model_armor[0].request_template_id : null
  model_armor_response_template_id = var.enable_model_armor ? module.model_armor[0].response_template_id : null

  model_armor_authz_hosts = var.enable_model_armor && var.mcp_internal_dns_zone != null ? [
    for svc in keys(var.mcp_services) :
    "${svc}.${trimsuffix(var.mcp_internal_dns_zone.domain, ".")}"
  ] : []

  authz_extension_fail_open = var.agent_gateway_authz_fail_open
  iap_iam_enforcement_mode  = var.agent_gateway_iap_iam_enforcement_mode

  dns_peering_config = local.agent_gateway_dns_peering_config_effective

  depends_on = [time_sleep.wait_enable_apis, module.networking, module.mcp_internal_lb]
}

resource "google_dns_record_set" "mcp_service" {
  for_each = var.mcp_services

  project      = var.project_id
  managed_zone = module.networking.mcp_internal_dns_zone_name
  name         = "${each.key}.${module.networking.mcp_internal_dns_domain}"
  type         = "A"
  ttl          = 60
  rrdatas      = [module.mcp_internal_lb.ip_address]
}

resource "google_project_iam_member" "discoveryengine_admin" {
  for_each = toset(var.platform_admin_members)
  project  = var.project_id
  role     = "roles/discoveryengine.admin"
  member   = each.key
}

resource "google_project_iam_member" "run_admin" {
  for_each = toset(var.platform_admin_members)
  project  = var.project_id
  role     = "roles/run.admin"
  member   = each.key
}

module "agent_registry_endpoints" {
  source = "../../modules/agent_registry"

  project_id = var.project_id
  location   = var.region

  google_apis     = var.agent_registry_google_apis
  custom_services = var.agent_registry_custom_services

  mcp_servers = {
    for name in keys(var.mcp_services) : name => {
      tool_spec_path = lookup(var.mcp_tool_specs, name, null) != null ? abspath("${path.root}/${var.mcp_tool_specs[name]}") : null
    }
  }

  # Registers each service at `https://<svc>.<mcp_internal_dns_zone.domain>/mcp`
  mcp_url_mode            = "internal_lb"
  mcp_internal_dns_domain = local.mcp_internal_dns_domain_or_null
  mcp_service_urls        = module.mcp_services.service_urls

  depends_on = [time_sleep.wait_enable_apis, module.mcp_services, module.mcp_internal_lb]
}
