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
  description = "The parent resource id"
}

output "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code."
  value       = var.terraform_service_account
}

output "state_bucket" {
  description = "State bucket"
  value       = module.harness.state_bucket
}

output "instance_region" {
  description = "Instance region"
  value       = var.instance_region
}

/******************************************
  Harness Projects
*****************************************/
output "kms_project_id" {
  description = "Project ID for Cloud Key Management Service (KMS)."
  value       = module.harness.kms_project_id
}

output "kms_project_number" {
  description = "Project number for Cloud Key Management Service (KMS)."
  value       = module.harness.kms_project_number
}

output "logging_project_id" {
  description = "Loggin project ID."
  value       = module.harness.logging_project_id
}

output "logging_project_name" {
  description = "Logging Project name"
  value       = module.harness.logging_project_name
}

output "seed_project_id" {
  description = "Artifact Publish project ID."
  value       = module.harness.seed_project_id
}

output "machine_learning_project_id" {
  description = "Machine Learning Project ID."
  value       = module.harness.machine_learning_project_id
}

output "machine_learning_project_name" {
  description = "Machine Learning project Name."
  value       = module.harness.machine_learning_project_name
}

output "service_catalog_project_id" {
  description = "Project ID for Service Catalog."
  value       = module.harness.service_catalog_project_id
}

output "service_catalog_project_name" {
  description = "Service Catalog project number."
  value       = module.harness.service_catalog_project_name
}

output "artifact_publish_project_id" {
  description = "Artifact Publish project ID."
  value       = module.harness.artifact_publish_project_id
}

output "artifact_publish_project_number" {
  description = "Artifact Publish project number"
  value       = module.harness.artifact_publish_project_number
}

output "artifact_publish_project_name" {
  description = "Artifact Publish project Name."
  value       = module.harness.artifact_publish_project_name
}

/******************************************
  KMS keyrings and crypto keys
*****************************************/
output "kms_keyrings" {
  description = "KMS keyring."
  value       = module.vertex_ai.key_rings
}

output "kms_keys" {
  description = "Projects Key ID for encrytion"
  value       = module.vertex_ai.kms_keys
}

output "keyrings_regions" {
  description = "KMS Keyring region."
  value       = var.keyring_regions
}

output "keyring_name" {
  description = "Key Ring name"
  value       = var.keyring_name
}

/******************************************
  Network
*****************************************/

output "machine_learning_network_name" {
  description = "The name of the machine learning VPC being created."
  value       = module.harness.machine_learning_network_name
}

output "restricted_network_self_link" {
  description = "The URI of the machine learning VPC being created."
  value       = module.harness.restricted_network_self_link
}

output "machine_learning_subnets_self_link" {
  description = "The self-links of the machine learning subnets being created."
  value       = module.harness.machine_learning_subnets_self_link
}

/******************************************
  VPC Service Controls
*****************************************/
output "access_level_name_dry_run" {
  description = "Access context manager access level name for the dry-run perimeter"
  value       = module.vertex_ai.access_level_name_dry_run
}

output "access_level_name" {
  description = "Access context manager access level name for the enforced perimeter"
  value       = module.vertex_ai.access_level_name
}

output "service_perimeter_name" {
  description = "Perimeter name."
  value       = module.vertex_ai.service_perimeter_name
}

/******************************************
  Service Catalog
*****************************************/
output "cloud_source_service_catalog_repo_name" {
  description = "Service Catalog cloud source repository name."
  value       = var.cloud_source_service_catalog_repo_name
}

output "service_catalog_repo_id" {
  description = "ID of the Service Catalog repository"
  value       = module.vertex_ai.service_catalog_repo_id
}

output "service_catalog_cloudbuild_trigger_id" {
  value = module.vertex_ai.service_catalog_cloudbuild_trigger_id
}

output "storage_bucket_name" {
  description = "Name of storage bucket created"
  value       = module.vertex_ai.storage_bucket_name
}

output "log_bucket" {
  description = "Log bucket to be used by Service Catalog Bucket."
  value       = module.vertex_ai.log_bucket
}

/******************************************
  Artifact Publish
*****************************************/
output "cloud_source_artifacts_repo_name" {
  description = "Artifacts cloud source repository name."
  value       = var.cloud_source_artifacts_repo_name
}

output "artifact_publish_cloudbuild_trigger_id" {
  value = module.vertex_ai.artifact_publish_cloudbuild_trigger_id
}

output "artifacts_repo_id" {
  description = "ID of the Artifacts repository"
  value       = module.vertex_ai.artifacts_repo_id
}

/******************************************
  Firewall roles
*****************************************/
output "allow_ingress_firewall_rule_ip_range" {
  description = "Firewall rules"
  value       = module.vertex_ai.allow_ingress_firewall_rule_ip_range
}
