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
  artifact_tf_sa_roles = [
    "roles/artifactregistry.admin",
    "roles/cloudbuild.builds.editor",
    "roles/cloudbuild.connectionAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/secretmanager.admin",
    "roles/source.admin",
    "roles/storage.admin",
  ]

  enable_artifacts_bindings = try(var.artifacts_infra_pipeline_sa != null && var.artifacts_infra_pipeline_sa != "", false)
}

module "app_infra_artifacts_project" {
  source = "../ml_single_project"

  org_id              = var.org_id
  billing_account     = var.billing_account
  folder_id           = var.folder_id
  environment         = var.environment
  project_budget      = var.project_budget
  project_prefix      = var.project_prefix
  key_rings           = var.key_rings
  remote_state_bucket = var.remote_state_bucket
  prevent_destroy     = var.prevent_destroy

  activate_apis = [
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
  # Metadata
  project_suffix             = var.artifacts_project_suffix
  application_name           = var.artifacts_application_name
  billing_code               = var.billing_code
  primary_contact            = var.primary_contact
  secondary_contact          = var.secondary_contact
  business_code              = var.business_code
  environment_kms_project_id = var.environment_kms_project_id
  project_name               = "${var.project_prefix}-${local.env_code}-${var.business_code}${var.artifacts_project_suffix}"
}

resource "google_kms_crypto_key_iam_member" "ml_key" {
  for_each = local.enable_artifacts_bindings ? module.app_infra_artifacts_project.kms_keys : {}

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${var.artifacts_infra_pipeline_sa}"
}

resource "google_project_iam_member" "artifact_tf_sa_roles" {
  for_each = local.enable_artifacts_bindings ? toset(local.artifact_tf_sa_roles) : toset([])

  project = module.app_infra_artifacts_project.project_id
  role    = each.key
  member  = "serviceAccount:${var.artifacts_infra_pipeline_sa}"
}

// Add Service Agent for Cloud Build
resource "google_project_iam_member" "artifact_cloudbuild_agent" {
  project = module.app_infra_artifacts_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.app_infra_artifacts_project.project_number}@cloudbuild.gserviceaccount.com"
}

// Add Repository for Artifact repo
resource "google_sourcerepo_repository" "artifact_repo" {
  project = module.app_infra_artifacts_project.project_id
  name    = var.cloud_source_artifacts_repo_name
}
