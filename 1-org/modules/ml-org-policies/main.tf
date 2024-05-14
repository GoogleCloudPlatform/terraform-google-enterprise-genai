/**
 * Copyright 2024 Google LLC
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

  ml_boolean_type_organization_policies = toset([
    #Disable file downloads on new Vertex AI Workbench instances
    #Control ID: VAI-CO-4.2
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "ainotebooks.disableFileDownloads",

    #Disable root access on new Vertex AI Workbench user-managed notebooks and instances
    #Control ID: VAI-CO-4.3
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "ainotebooks.disableRootAccess",

    #Disable terminal on new Vertexx AI Workbench instances
    #Control ID: VAI-CO-4.4
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "ainotebooks.disableTerminal",

    #Restrict public IP access on new Vertex AI Workbench notebooks and instances
    #Control ID: VAI-CO-4.7
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "ainotebooks.restrictPublicIp",

    #Require automatic scheduled upgrades on new Vertex AI Workbench user-managed notebooks and instances
    #Control ID: VAI-CO-4.6
    #NIST 800-53: AC-3 AC-17 AC-20
    #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
    "ainotebooks.requireAutoUpgradeSchedule",

    #Require VPC Connector
    #Control ID: CF-CO-4.4
    #NIST 800-53: SC-7 SC-8
    #CRI Profile: PR.AC-5.1 PR.AC-5.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1 PR.PT-4.1 DE.CM-1.1 DE.CM-1.2 DE.CM-1.3 DE.CM-1.4
    "cloudfunctions.requireVPCConnector"
  ])

  vertex_vpc_networks_format = {
    "organization" = "under:organizations/%s",
    "folder"       = "under:folders/%s",
    "project"      = "under:projects/%s"
  }

  access_scope                = var.folder_id != "" ? ["under:folders/${var.folder_id}"] : ["under:organizations/${var.org_id}"]
  policy_for                  = var.folder_id != "" ? "folder" : "organization"
  under_format                = lookup(local.vertex_vpc_networks_format, var.allowed_vertex_vpc_networks.parent_type, "%s")
  allowed_vertex_vpc_networks = [for id in var.allowed_vertex_vpc_networks.ids : format(local.under_format, id)]
}

module "ml_organization_policies_type_boolean" {
  source   = "terraform-google-modules/org-policy/google"
  version  = "~> 5.1"
  for_each = local.ml_boolean_type_organization_policies

  organization_id = var.org_id
  folder_id       = var.folder_id
  policy_for      = local.policy_for
  policy_type     = "boolean"
  enforce         = "true"
  constraint      = "constraints/${each.value}"
}

/******************************************
  Cloud build
*******************************************/

module "allowed_integrations" {
  #Allowed Integrations
  #Control ID: CB-CO-6.2
  #NIST 800-53: AC-3 AC-12 AC-17 AC-20
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.AC-7.1 PR.AC-7.2 PR.PT-3.1 PR-PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = 1
  allow             = var.allowed_integrations
  constraint        = "constraints/cloudbuild.allowedIntegrations"
}

/*****************************************
  Common
******************************************/

module "restrict_tls_versions" {
  #Restrict TLS Versions Supported by Google APIs
  #Control ID: COM-CO-1.1
  #NIST 800-53: SC-8 SC-13
  #CRI Profile: PR.DS-2.1 PR.DS-2.2 PR.DS-5.1

  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id  = var.org_id
  folder_id        = var.folder_id
  policy_for       = local.policy_for
  policy_type      = "list"
  deny_list_length = length(var.restricted_tls_versions)
  deny             = var.restricted_tls_versions
  constraint       = "constraints/gcp.restrictTLSVersion"
}

module "restrict_cmek_key_projects" {
  #Customer Managed Encryption Keys (1 of 2)
  #Control ID: COM-CO-2.2
  #NIST 800-53 SC-12 SC-13
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = 1
  allow             = local.access_scope
  constraint        = "constraints/gcp.restrictCmekCryptoKeyProjects"
}

module "restrict_non_cmek_services" {
  #Customer Managed Encryption Keys (2 of 2)
  #Control ID: COM-CO-2.3
  #NIST 800-53: SC-12
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id  = var.org_id
  folder_id        = var.folder_id
  policy_for       = local.policy_for
  policy_type      = "list"
  deny_list_length = length(var.restricted_non_cmek_services)
  deny             = var.restricted_non_cmek_services
  constraint       = "constraints/gcp.restrictNonCmekServices"
}

module "restrict_service_usage" {
  #Restrict Resource Service Usage
  #Control ID: RM-CO-4.1
  #NIST 800-53: AC-3 AC-17 AC-20
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id  = var.org_id
  folder_id        = var.folder_id
  policy_for       = local.policy_for
  policy_type      = "list"
  deny_list_length = length(var.restricted_services)
  deny             = var.restricted_services
  constraint       = "constraints/gcp.restrictServiceUsage"
}

module "allowed_locations" {
  #Resource Location Restriction
  #Control ID: RM-CO-4.2
  #NIST 800-53: AC-3 AC-17 AC-20
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(var.allowed_locations)
  allow             = var.allowed_locations
  constraint        = "constraints/gcp.resourceLocations"
}

/******************************************
  VPC
*******************************************/

module "restrict_vm_ip_forwarding" {
  #Restrict VM IP Forwarding
  #Control ID: VPC-CO-6.3
  #NIST 800-53: SC-7 SC-8
  #CRI Profile: PR.AC-5.1 PR.AC-5.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1 PR.PT-4.1 DE.CM-1.1 DE.CM-1.2 DE.CM-1.3 DE.CM-1.4
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id  = var.org_id
  folder_id        = var.folder_id
  policy_for       = local.policy_for
  policy_type      = "list"
  deny_list_length = 1
  deny             = local.access_scope
  constraint       = "constraints/compute.vmCanIpForward"
}

/******************************************
  Vertex AI
*******************************************/

module "vertexai_workbench_access_mode" {
  #Default access mode for Vertex AI Workbench notebooks and isntances
  #Control ID: VAI-CO-4.1
  #NIST 800-53: AC-3 AC-17 AC-20
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(var.allowed_vertex_access_modes)
  allow             = var.allowed_vertex_access_modes
  constraint        = "constraints/ainotebooks.accessMode"
}

module "vertexai_allowed_images" {
  #Restrict environment options on new Vertex AI Workbench notebooks and instances.
  #Control ID: VAI-CO-4.5
  #NIST 800-53: AC-3 AC-17 AC-20
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(var.allowed_vertex_images)
  allow             = var.allowed_vertex_images
  constraint        = "constraints/ainotebooks.environmentOptions"
}

module "restrict_vertex_notebook_vpc_networks" {
  #Restrict VPC networks on new Vertex AI Workbench instances
  #Control ID: VAI-CO-4.8
  #NIST 800-53 SC-7 SC-8
  #CRI Profile: PR.AC-3.1 PR.AC-3.2 PR.AC-4.1 PR.AC-4.2 PR.AC-4.3 PR.AC-6.1 PR.PT-3.1 PR.PT-4.1
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  organization_id   = var.org_id
  folder_id         = var.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow_list_length = length(local.allowed_vertex_vpc_networks)
  allow             = local.allowed_vertex_vpc_networks
  constraint        = "constraints/ainotebooks.restrictVpcNetworks"
}
