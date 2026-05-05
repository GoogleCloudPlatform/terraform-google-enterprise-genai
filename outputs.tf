/**
 * Copyright 2026 Google LLC
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

/******************************************
  Projects
*****************************************/
output "kms_project_id" {
  description = "Cloud Key Management Service (KMS) project ID."
  value       = var.kms_project_id
}

output "logging_project_id" {
  description = "Logging project ID."
  value       = var.logging_project_id
}

output "artifact_publish_project_id" {
  description = "Artifact publishing project ID."
  value       = var.artifact_publish_project_id
}

output "service_catalog_project_id" {
  description = "Service Catalog project ID."
  value       = var.service_catalog_project_id
}

/******************************************
  KMS key rings
*****************************************/
output "key_rings" {
  description = "Key ring names created."
  value       = local.keyrings
}

output "kms_keys" {
  description = "KMS keys created by region and project."
  value = {
    for region, kms in module.kms_keyrings :
    region => kms.keys
  }
}

/******************************************
  Artifact Publishing
*****************************************/
output "cloud_source_artifacts_repo_name" {
  description = "Cloud Source repository name for artifact publishing."
  value       = var.cloud_source_artifacts_repo_name
}

output "artifacts_repo_id" {
  description = "ID of the artifacts repository."
  value       = module.artifact_publish.artifacts_repo_id
}

output "artifact_publish_cloudbuild_trigger_id" {
  description = "Cloud Build trigger ID for artifact publishing."
  value       = module.artifact_publish.cloudbuild_trigger_id
}

/******************************************
  Service Catalog
*****************************************/
output "cloud_source_service_catalog_repo_name" {
  description = "Cloud Source repository name for Service Catalog."
  value       = var.cloud_source_service_catalog_repo_name
}

output "service_catalog_repo_id" {
  description = "ID of the Service Catalog repository."
  value       = module.service_catalog.service_catalog_repo_id
}

output "service_catalog_cloudbuild_trigger_id" {
  description = "Cloud Build trigger ID for Service Catalog."
  value       = module.service_catalog.cloudbuild_trigger_id
}

output "storage_bucket_name" {
  description = "Name of the storage bucket created."
  value       = module.service_catalog.storage_bucket_name
}

output "log_bucket" {
  description = "Log bucket to be used by Service Catalog."
  value       = module.ml_logging.name
}

/******************************************
  VPC Service Controls
*****************************************/
output "access_context_manager_policy_id" {
  description = "Access Context Manager policy ID."
  value       = var.access_context_manager_policy_id
}

output "service_perimeter_name" {
  description = "Service perimeter name."
  value       = length(module.service_control) > 0 ? module.service_control[0].service_perimeter_name : null
}

output "access_level_name" {
  value       = length(module.service_control) > 0 ? module.service_control[0].access_level_name : null
  description = "Access Context Manager access level name."
}

output "access_level_name_dry_run" {
  value       = length(module.service_control) > 0 ? module.service_control[0].access_level_name_dry_run : null
  description = "Access Context Manager access level name for the dry-run perimeter."
}

/******************************************
  Firewall rules
*****************************************/

output "allow_ingress_firewall_rule_ip_range" {
  description = "IP range for the allow ingress firewall rule."
  value = distinct(concat(
    data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4,
    data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4,
    data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4,
  ))
}
