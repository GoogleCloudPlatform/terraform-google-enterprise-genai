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

output "parent_resource_id" {
  value       = var.parent_folder
  description = "The parent resource ID."
}

output "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code."
  value       = var.terraform_service_account
}

output "remote_state_bucket" {
  description = "Bucket used for storing Terraform state for the standalone example in the seed project."
  value       = module.harness.remote_state_bucket
}

output "instance_region" {
  description = "Region where the resources were created."
  value       = var.default_region
}

/******************************************
  Harness Projects
*****************************************/
output "kms_project_id" {
  description = "Cloud Key Management Service (KMS) project ID."
  value       = module.harness.kms_project_id
}

output "kms_project_number" {
  description = "Cloud Key Management Service (KMS) project number."
  value       = module.harness.kms_project_number
}

output "logging_project_id" {
  description = "Logging project ID."
  value       = module.harness.logging_project_id
}

output "logging_project_name" {
  description = "Logging project name."
  value       = module.harness.logging_project_name
}

output "seed_project_id" {
  description = "Seed project ID."
  value       = module.harness.seed_project_id
}

output "machine_learning_project_id" {
  description = "Machine Learning project ID."
  value       = module.harness.machine_learning_project_id
}

output "machine_learning_project_name" {
  description = "Machine Learning project name."
  value       = module.harness.machine_learning_project_name
}

output "service_catalog_project_id" {
  description = "Service Catalog project ID."
  value       = module.harness.service_catalog_project_id
}

output "service_catalog_project_name" {
  description = "Service Catalog project name."
  value       = module.harness.service_catalog_project_name
}

output "artifact_publish_project_id" {
  description = "Artifact publishing project ID."
  value       = module.harness.artifact_publish_project_id
}

output "artifact_publish_project_number" {
  description = "Artifact publishing project number."
  value       = module.harness.artifact_publish_project_number
}

output "artifact_publish_project_name" {
  description = "Artifact publishing project name."
  value       = module.harness.artifact_publish_project_name
}

/******************************************
  KMS key rings and crypto keys
*****************************************/
output "kms_keyrings" {
  description = "KMS key rings."
  value       = module.vertex_ai.key_rings
}

output "kms_keys" {
  description = "KMS key IDs for encryption."
  value       = module.vertex_ai.kms_keys
}

output "keyrings_regions" {
  description = "KMS key ring regions."
  value       = var.keyring_regions
}

output "keyring_name" {
  description = "Key ring name."
  value       = var.keyring_name
}

/******************************************
  Network
*****************************************/

output "machine_learning_network_name" {
  description = "The name of the Machine Learning VPC being created."
  value       = module.harness.machine_learning_network_name
}

output "restricted_network_self_link" {
  description = "The URI of the Machine Learning VPC being created."
  value       = module.harness.restricted_network_self_link
}

output "machine_learning_subnets_self_link" {
  description = "The self-links of the Machine Learning subnets being created."
  value       = module.harness.machine_learning_subnets_self_link
}

/******************************************
  VPC Service Controls
*****************************************/
output "access_level_name_dry_run" {
  description = "Access Context Manager access level name for the dry-run perimeter."
  value       = module.vertex_ai.access_level_name_dry_run
}

output "access_level_name" {
  description = "Access Context Manager access level name for the enforced perimeter."
  value       = module.vertex_ai.access_level_name
}

output "service_perimeter_name" {
  description = "Access Context Manager service perimeter name."
  value       = module.vertex_ai.service_perimeter_name
}

/******************************************
  Service Catalog
*****************************************/
output "cloud_source_service_catalog_repo_name" {
  description = "Service Catalog Cloud Source repository name."
  value       = var.cloud_source_service_catalog_repo_name
}

output "service_catalog_repo_id" {
  description = "ID of the Service Catalog repository."
  value       = module.vertex_ai.service_catalog_repo_id
}

output "service_catalog_cloudbuild_trigger_id" {
  description = "Service Catalog Cloud Build trigger ID."
  value       = module.vertex_ai.service_catalog_cloudbuild_trigger_id
}

output "storage_bucket_name" {
  description = "Name of the storage bucket created."
  value       = module.vertex_ai.storage_bucket_name
}

output "log_bucket" {
  description = "Log bucket to be used by Service Catalog."
  value       = module.vertex_ai.log_bucket
}

/******************************************
  Artifact Publishing
*****************************************/
output "cloud_source_artifacts_repo_name" {
  description = "Artifacts Cloud Source repository name."
  value       = var.cloud_source_artifacts_repo_name
}

output "artifact_publish_cloudbuild_trigger_id" {
  description = "Artifact publishing Cloud Build trigger ID."
  value       = module.vertex_ai.artifact_publish_cloudbuild_trigger_id
}

output "artifacts_repo_id" {
  description = "Artifacts repository ID."
  value       = module.vertex_ai.artifacts_repo_id
}

/******************************************
  Firewall rules
*****************************************/
output "allow_ingress_firewall_rule_ip_range" {
  description = "Allow ingress firewall rule IP range."
  value       = module.vertex_ai.allow_ingress_firewall_rule_ip_range
}
