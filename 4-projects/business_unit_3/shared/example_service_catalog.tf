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

locals {
  service_catalog_tf_sa_roles = [
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudbuild.connectionAdmin",
    "roles/secretmanager.admin",
    "roles/storage.admin",
    "roles/source.admin",
  ]

  cloud_source_service_catalog_repo_name = "service-catalog"
}

module "app_service_catalog_project" {
  source = "../../modules/single_project"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id              = local.org_id
  billing_account     = local.billing_account
  folder_id           = local.common_folder_name
  environment         = "common"
  project_budget      = var.project_budget
  project_prefix      = local.project_prefix
  key_rings           = local.shared_kms_key_ring
  remote_state_bucket = var.remote_state_bucket
  activate_apis = [
    "logging.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
  # Metadata
  project_suffix    = local.cloud_source_service_catalog_repo_name
  application_name  = "app-infra-ml"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "bu3"
}

resource "google_kms_crypto_key_iam_member" "sc_key" {
  for_each      = module.app_service_catalog_project[0].kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-service-catalog"]}"
}

// Grab Service Agent for Secret Manager
resource "google_project_service_identity" "secretmanager_agent" {
  provider = google-beta
  project  = module.app_service_catalog_project[0].project_id
  service  = "secretmanager.googleapis.com"
}

// Add Secret Manager Service Agent to key with encrypt/decrypt permissions 
resource "google_kms_crypto_key_iam_member" "secretmanager_agent" {
  for_each      = module.app_service_catalog_project[0].kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager_agent.email}"
}

// Grab Service Agent for Storage
resource "google_project_service_identity" "storage" {
  provider = google-beta
  project  = module.app_service_catalog_project[0].project_id
  service  = "storage.googleapis.com"
}
// Add Service Agent for Storage
resource "google_kms_crypto_key_iam_member" "storage_agent" {
  for_each      = module.app_service_catalog_project[0].kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${module.app_service_catalog_project[0].project_number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service_identity.storage]
}

// Add infra pipeline SA encrypt/decrypt permissions
resource "google_kms_crypto_key_iam_member" "storage-kms-key-binding" {
  for_each      = module.app_service_catalog_project[0].kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-service-catalog"]}"
}

resource "google_project_iam_member" "service_catalog_tf_sa_roles" {
  for_each = toset(local.service_catalog_tf_sa_roles)
  project  = module.app_service_catalog_project[0].project_id
  role     = each.key
  member   = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-service-catalog"]}"
}

// Add Service Agent for Cloud Build
resource "google_project_iam_member" "cloudbuild_agent" {
  project = module.app_service_catalog_project[0].project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.app_service_catalog_project[0].project_number}@cloudbuild.gserviceaccount.com"
}

// Add Service Catalog Source Repository

resource "google_sourcerepo_repository" "service_catalog" {
  project = module.app_service_catalog_project[0].project_id
  name    = local.cloud_source_service_catalog_repo_name
}

/**
 * When Jenkins CICD is used for deployment this resource
 * is created to terraform validation works.
 * Without this resource, this module creates zero resources
 * and it breaks terraform validation throwing the error below:
 * ERROR: [Terraform plan json does not contain resource_changes key]
 */
resource "null_resource" "jenkins_cicd_service_catalog" {
  count = !local.enable_cloudbuild_deploy ? 1 : 0
}
