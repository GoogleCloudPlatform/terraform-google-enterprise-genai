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

module "app_cloudbuild_project" {
  source = "../single_project"

  org_id          = local.org_id
  billing_account = local.billing_account
  folder_id       = var.folder_id
  environment     = "development"
  project_budget  = var.project_budget
  project_prefix  = local.project_prefix
  activate_apis   = var.activate_apis


  # Metadata
  project_suffix    = var.project_suffix
  application_name  = var.application_name
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = var.business_code
}

module "app_pipelines" {
  source = "../infra_pipelines"

  org_id                      = local.org_id
  cloudbuild_project_id       = module.app_cloudbuild_project.project_id
  cloud_builder_artifact_repo = local.cloud_builder_artifact_repo
  remote_tfstate_bucket       = local.projects_remote_bucket_tfstate
  billing_account             = local.billing_account
  default_region              = var.default_region
  app_infra_repos             = [var.repo_name]
  private_worker_pool_id      = local.cloud_build_private_worker_pool_id

}

resource "google_kms_crypto_key" "app_key" {
  for_each        = toset(local.environment_kms_key_ring)
  name            = module.app_cloudbuild_project.project_name
  key_ring        = each.key
  rotation_period = var.key_rotation_period
  lifecycle {
    prevent_destroy = false
  }
}

// Create key for project
resource "google_kms_crypto_key_iam_member" "app_key" {
  for_each      = google_kms_crypto_key.app_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${module.app_pipelines.terraform_service_accounts[var.repo_name]}"
}
// Grab Service Agent for Secret Manager
resource "google_project_service_identity" "secretmanager_agent" {
  provider = google-beta
  project  = module.app_cloudbuild_project.project_id
  service  = "secretmanager.googleapis.com"
}

// Add Secret Manager Service Agent to key with encrypt/decrypt permissions 
resource "google_kms_crypto_key_iam_member" "secretmanager_agent" {
  for_each      = google_kms_crypto_key.app_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager_agent.email}"
}
