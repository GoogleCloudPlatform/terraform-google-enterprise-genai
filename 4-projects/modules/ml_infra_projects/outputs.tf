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

output "service_catalog_project_id" {
  description = "Service Catalog Project ID."
  value       = try(module.app_service_catalog_project.project_id, "")
}

output "common_artifacts_project_id" {
  description = "App Infra Artifacts Project ID."
  value       = try(module.app_infra_artifacts_project.project_id, "")
}

output "service_catalog_repo_name" {
  description = "The name of the Service Catalog repository."
  value       = google_sourcerepo_repository.service_catalog.name
}

output "service_catalog_repo_id" {
  description = "ID of the Service Catalog repository."
  value       = google_sourcerepo_repository.service_catalog.id
}

output "artifacts_repo_name" {
  description = "The name of the Artifacts repository."
  value       = google_sourcerepo_repository.artifact_repo.name
}

output "artifacts_repo_id" {
  description = "ID of the Artifacts repository."
  value       = google_sourcerepo_repository.artifact_repo.id
}
