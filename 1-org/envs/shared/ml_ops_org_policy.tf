/**
 * Copyright 2023 Google LLC
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
  organization_id = local.parent_folder != "" ? null : local.org_id
  folder_id       = local.parent_folder != "" ? local.parent_folder : null
  policy_for      = local.parent_folder != "" ? "folder" : "organization"

  boolean_type_organization_policies = toset([
    "ainotebooks.disableFileDownloads",
    "ainotebooks.disableRootAccess",
    "ainotebooks.disableTerminal",
    "ainotebooks.restrictPublicIp",
    "ainotebooks.requireAutoUpgradeSchedule",
    "cloudfunctions.requireVPCConnector"
  ])

  private_pools = [local.cloud_build_private_worker_pool_id]
  restricted_services = []
  restricted_locations = []
  allowed_integrations = ["github.com"]
  allowed_tls_versions = ["TLS_VERSION_1.1", "TLS_VERSION_1.2"]
  allowed_vertex_images = []
  allowed_vertex_access_modes = ["single-user", "service-account"]
}

module "ml_organization_policies_type_boolean" {
  source   = "terraform-google-modules/org-policy/google"
  version  = "~> 5.1"
  for_each = local.boolean_type_organization_policies

  organization_id = local.organization_id
  folder_id       = local.folder_id
  policy_for      = local.policy_for
  policy_type     = "boolean"
  enforce         = "false"
  constraint      = "constraints/${each.value}"
}

/******************************************
  Cloud build
*******************************************/

module "allowed_integrations" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = 1
  allow             = [local.allowed_integrations]
  constraint        = "constraints/cloudbuild.allowedIntegrations"
}

/*****************************************
  Common
******************************************/

module "restrict_tls_versions" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = length(local.allowed_tls_versions)
  allow             = [local.allowed_tls_versions]
  constraint        = "constraints/gcp.restrictTLSVersion"
}

module "restrict_cmek_key_projects" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = 1
  allow             = [local.folder_id]
  constraint        = "constraints/gcp.restrictCmekCryptoKeyProjects"
}

module "restrict_service_usage" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  deny_list_length  = length(local.restricted_services)
  deny              = [local.restricted_services]
  constraint        = "constraints/gcp.restrictServiceUsage"
}

module "restricted_locations" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  deny_list_length  = length(local.restricted_locations)
  deny              = [local.restricted_locations]
  constraint        = "constraints/gcp.resourceLocations"
}

/******************************************
  VPC
*******************************************/

module "restrict_vm_ip_forwarding" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  deny_list_length  = 1
  deny              = ["under:projects/${local.project_id}"]
  constraint        = "constraints/compute.vmCanIpForward"
}

module "restrict_vertex_notebook_vpc_networks" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = 1
  allow             = ["under:projects/${local.project_id}"]
  constraint        = "constraints/ainotebooks.restrictVpcNetworks"
}

/******************************************
  Vertex AI
*******************************************/

module "vertexai_workbench_access_mode" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = length(local.allowed_vertex_access_modes)
  allow             = [local.allowed_vertex_access_modes]
  constraint        = "constraints/ainotebooks.accessMode"
}

module "vertexai_allowed_images" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  enforce           = "false"
  allow_list_length = length(local.allowed_vertex_images)
  allow             = [local.allowed_vertex_images]
  constraint        = "constraints/ainotebooks.environmentOptions"
}