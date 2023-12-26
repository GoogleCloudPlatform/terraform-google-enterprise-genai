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

#### Resources related to Cloud Composer in the Operational environments ####

# Composer Service Account
resource "google_service_account" "composer" {
  account_id   = "composer"
  display_name = "${title(var.env)} Composer Service Account"
  description  = "Service account to be used by Cloud Composer"
  project      = module.app_cloudbuild_project.project_id
}

resource "google_project_iam_member" "composer_worker_composer_service_account" {
  project = module.app_cloudbuild_project.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

# Pubsub
resource "google_project_service_identity" "pubsub" {
  provider = google-beta

  project = module.app_cloudbuild_project.project_id
  service = "pubsub.googleapis.com"
}

resource "google_project_iam_member" "pubsub_agent_kms" {
  project = module.app_cloudbuild_project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

# GKE
resource "google_project_service_identity" "gke" {
  provider = google-beta

  project = module.app_cloudbuild_project.project_id
  service = "container.googleapis.com"
}

resource "google_project_iam_member" "gke_agent_kms" {
  project = module.app_cloudbuild_project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_project_service_identity.gke.email}"
}

# Compute engine
resource "google_project_iam_member" "compute_agent_kms" {
  project = module.app_cloudbuild_project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${module.app_cloudbuild_project.project_number}@compute-system.iam.gserviceaccount.com"
}

# Big Query
resource "google_project_iam_member" "composer_bigquery" {
  project = module.app_cloudbuild_project.project_id
  role    = google_project_iam_custom_role.composer-sa-bq.id
  member  = format("serviceAccount:%s", google_service_account.composer.email)
}

# Vertex AI
resource "google_project_iam_member" "composer_vertex" {
  project = module.app_cloudbuild_project.project_id
  role    = google_project_iam_custom_role.composer-sa-vertex.id
  member  = format("serviceAccount:%s", google_service_account.composer.email)
}
