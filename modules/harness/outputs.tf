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

output "kms_project_id" {
  description = "KMS project ID."
  value       = module.kms_project.project_id
}

output "kms_project_number" {
  description = "KMS project number."
  value       = module.kms_project.project_number
}

output "seed_project_id" {
  description = "Seed project ID."
  value       = module.seed_project.project_id
}

output "logging_project_id" {
  description = "Logging project ID."
  value       = module.logging_project.project_id
}

output "logging_project_number" {
  description = "Logging project number."
  value       = module.logging_project.project_number
}

output "logging_project_name" {
  description = "Logging project number."
  value       = module.logging_project.project_name
}

output "machine_learning_project_id" {
  description = "Machine Learning project ID."
  value       = module.machine_learning_project.project_id
}

output "machine_learning_project_number" {
  description = "Machine Learning project number."
  value       = module.machine_learning_project.project_number
}

output "machine_learning_project_name" {
  description = "Machine Learning project Name."
  value       = module.machine_learning_project.project_name
}

output "artifact_publish_project_id" {
  description = "Artifact Publish project ID."
  value       = module.artifact_publish_project.project_id
}

output "artifact_publish_project_name" {
  description = "Artifact Publish project Name."
  value       = module.artifact_publish_project.project_id
}

output "artifact_publish_project_number" {
  description = "Artifact Publish project number."
  value       = module.artifact_publish_project.project_number
}

output "service_catalog_project_id" {
  description = "Service Catalog project ID."
  value       = module.service_catalog_project.project_id
}

output "service_catalog_project_number" {
  description = "Service Catalog project number."
  value       = module.service_catalog_project.project_number
}

output "service_catalog_project_name" {
  description = "Service Catalog project number."
  value       = module.service_catalog_project.project_name
}

output "machine_learning_network_name" {
  description = "The name of the machine learning VPC being created."
  value       = module.network.network_name
}

output "restricted_network_self_link" {
  description = "The URI of the machine learning VPC being created."
  value       = module.network.network_self_link
}

output "machine_learning_subnets_self_link" {
  description = "The self-links of the machine learning subnets being created."
  value       = module.network.subnets_self_links[0]
}

output "machine_learning_subnet_name" {
  description = "The name of the machine learning subnet being created."
  value       = module.network.subnets_names[0]
}

output "machine_learning_subnet_id" {
  description = "The id of the machine learning subnet being created."
  value       = module.network.subnets_ids[0]
}

/******************************************
  State bucket
*****************************************/
output "state_bucket" {
  description = "State bucket"
  value       = google_storage_bucket.terraform_state.name
}
