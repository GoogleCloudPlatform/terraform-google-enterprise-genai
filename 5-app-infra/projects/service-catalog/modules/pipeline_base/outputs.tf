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
  value       = google_service_account.trigger_sa
}

output "cloudbuild_v2_repo_id" {
  description = "Repository ID of cloudbuild repository"
  value       = google_cloudbuildv2_repository.repo.id
}

output "kms_key_id" {
  description = "Projects Key ID for encrytion"
  value       = data.google_kms_crypto_key.key.id
}

output "github_secret_version_name" {
  description = "Secret Version Name of key"
  value       = google_secret_manager_secret_version.github_secret_version.name
}
