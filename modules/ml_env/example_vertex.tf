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

locals {
  machine_learning_tf_sa_roles = [
    "roles/aiplatform.admin",
    "roles/artifactregistry.admin",
    "roles/bigquery.admin",
    "roles/cloudbuild.connectionAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/composer.admin",
    "roles/compute.admin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/iam.roleAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/notebooks.admin",
    "roles/pubsub.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/storage.admin",
  ]
}

/******************************************
  Machine Learning Project Pipeline SAs roles
*****************************************/

resource "google_project_iam_member" "machine_learning_pipeline_sa_roles" {
  for_each = toset(local.machine_learning_tf_sa_roles)

  project = var.machine_learning_project_id
  role    = each.key
  member  = "serviceAccount:${var.machine_learning_pipeline_sa}"
}

/******************************************
   Service Agents
*****************************************/

resource "google_project_service_identity" "cloud_build" {
  provider = google-beta

  project = var.machine_learning_project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service_identity" "notebooks" {
  provider = google-beta

  project = var.machine_learning_project_id
  service = "notebooks.googleapis.com"
}

resource "google_project_service_identity" "secrets" {
  provider = google-beta

  project = var.machine_learning_project_id
  service = "secretmanager.googleapis.com"
}

resource "google_project_service_identity" "aiplatform" {
  provider = google-beta

  project = var.machine_learning_project_id
  service = "aiplatform.googleapis.com"
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "60s"

  depends_on = [
    google_project_service_identity.cloud_build,
    google_project_service_identity.notebooks,
    google_project_service_identity.secrets,
    google_project_service_identity.aiplatform,
  ]
}

// Add cloudkms admin to sa
resource "google_kms_crypto_key_iam_member" "kms_admin" {

  crypto_key_id = var.kms_crypto_key
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${var.machine_learning_pipeline_sa}"
}

// Add crypto key viewer role to kms project
resource "google_project_iam_member" "cloud_build_kms_viewer" {
  project = var.kms_project_id
  role    = "roles/cloudkms.viewer"
  member  = "serviceAccount:${google_project_service_identity.cloud_build.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

resource "google_kms_crypto_key_iam_member" "secrets" {

  crypto_key_id = var.kms_crypto_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secrets.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

// Allow machine-learning sa access to service catalog cloud source repository
resource "google_sourcerepo_repository_iam_member" "read" {
  project    = var.service_catalog_project_id
  repository = var.cloud_source_artifacts_repo_name
  role       = "roles/viewer"
  member     = "serviceAccount:${var.machine_learning_pipeline_sa}"
}

// Add Artifact Registry Access to Vertex AI Agent
resource "google_project_iam_member" "access_artifacts" {
  project = var.artifact_publish_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${var.machine_learning_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_30_seconds]
}
