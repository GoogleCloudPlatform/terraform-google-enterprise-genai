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

locals {
  service_catalog_tf_sa_roles = [
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudbuild.connectionAdmin",
    "roles/secretmanager.admin",
    "roles/storage.admin",
    "roles/source.admin",
  ]
  enable_service_catalog_bindings = try(var.service_catalog_infra_pipeline_sa != null && var.service_catalog_infra_pipeline_sa != "", false)
}

module "app_service_catalog_project" {
  source = "../ml_single_project"

  org_id              = var.org_id
  billing_account     = var.billing_account
  folder_id           = var.folder_id
  environment         = var.environment
  project_budget      = var.project_budget
  project_prefix      = var.project_prefix
  key_rings           = var.key_rings
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
  project_suffix             = var.service_catalog_project_suffix
  application_name           = var.service_catalog_application_name
  billing_code               = var.billing_code
  primary_contact            = var.primary_contact
  secondary_contact          = var.secondary_contact
  business_code              = var.business_code
  environment_kms_project_id = var.environment_kms_project_id
  project_name               = "${var.project_prefix}-${local.env_code}-${var.business_code}${var.service_catalog_project_suffix}"
  prevent_destroy            = var.prevent_destroy
}

resource "google_kms_crypto_key_iam_member" "sc_key" {
  for_each = local.enable_service_catalog_bindings ? module.app_service_catalog_project.kms_keys : {}

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${var.service_catalog_infra_pipeline_sa}"
}

// Grab Service Agent for Secret Manager
resource "google_project_service_identity" "secretmanager_agent" {
  provider = google-beta

  project = module.app_service_catalog_project.project_id
  service = "secretmanager.googleapis.com"
}

// Add Secret Manager Service Agent to key with encrypt/decrypt permissions
resource "google_kms_crypto_key_iam_member" "secretmanager_agent" {
  for_each = module.app_service_catalog_project.kms_keys

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager_agent.email}"
}

// Grab Service Agent for Storage
resource "google_project_service_identity" "storage" {
  provider = google-beta

  project = module.app_service_catalog_project.project_id
  service = "storage.googleapis.com"
}
// Add Service Agent for Storage
resource "google_kms_crypto_key_iam_member" "storage_agent" {
  for_each = module.app_service_catalog_project.kms_keys

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${module.app_service_catalog_project.project_number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service_identity.storage]
}

// Add infra pipeline SA encrypt/decrypt permissions
resource "google_kms_crypto_key_iam_member" "storage-kms-key-binding" {
  for_each = local.enable_service_catalog_bindings ? module.app_service_catalog_project.kms_keys : {}

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.service_catalog_infra_pipeline_sa}"
}

resource "google_project_iam_member" "service_catalog_tf_sa_roles" {
  for_each = local.enable_service_catalog_bindings ? toset(local.service_catalog_tf_sa_roles) : toset([])

  project = module.app_service_catalog_project.project_id
  role    = each.key
  member  = "serviceAccount:${var.service_catalog_infra_pipeline_sa}"
}

// Add Service Agent for Cloud Build
resource "google_project_iam_member" "cloudbuild_agent" {
  project = module.app_service_catalog_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.app_service_catalog_project.project_number}@cloudbuild.gserviceaccount.com"
}

// Add Service Catalog Source Repository
resource "google_sourcerepo_repository" "service_catalog" {
  project = module.app_service_catalog_project.project_id
  name    = var.cloud_source_service_catalog_repo_name
}
