/**
 * Copyright 2022 Google LLC
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
  service_agents = [
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
  ]

  kms_secret_sa_accounts = [
    "serviceAccount:${google_service_account.composer.email}",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@gs-project-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@compute-system.iam.gserviceaccount.com",
    "serviceAccount:service-${module.app_cloudbuild_project.project_number}@compute-system.iam.gserviceaccount.com",
  ]

  # sa_account_to_crypto_key_id = [
  #   for key, value in module.app_cloudbuild_project.crypto_key : [
  #     for sa in local.kms_secret_sa_accounts : {
  #       id         = value.id
  #       sa_account = sa
  #     }
  #   ]
  # ]
}


// Grab Service Agent for Secret Manager
resource "google_project_service_identity" "service_agents_kms" {
  for_each = toset(local.service_agents)
  provider = google-beta
  project  = module.app_cloudbuild_project.project_id
  service  = each.key
}

resource "google_kms_crypto_key_iam_member" "app_key" {
  for_each      = module.app_cloudbuild_project.crypto_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${local.app_infra_pipeline_service_accounts[var.repo_name]}"
}

// Add Secret Manager Service Agent to key with encrypt/decrypt permissions 
resource "google_kms_crypto_key_iam_binding" "secretmanager_agent" {
  for_each      = module.app_cloudbuild_project.crypto_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = local.kms_secret_sa_accounts
}
