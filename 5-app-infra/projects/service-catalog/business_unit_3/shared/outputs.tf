/**
 * Copyright 2021 Google LLC
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

output "trigger_sa_account_id" {
  description = "Account id of service account cloudbuild."
  value       = module.service_catalog_pipeline.trigger_sa_account_id
}

output "cloudbuild_v2_repo_id" {
  description = "Repository ID of cloudbuild repository"
  value       = module.service_catalog_pipeline.cloudbuild_v2_repo_id
}

output "kms_key_id" {
  description = "Projects Key ID for encrytion"
  value       = module.service_catalog_pipeline.kms_key_id
}

output "storage_bucket_name" {
  description = "Name of storage bucket created"
  value       = module.service_catalog.storage_bucket_name
}

output "cloudbuild_trigger_id" {
  description = "Id of Cloud Build Trigger"
  value       = module.service_catalog.cloudbuild_trigger_id
}
