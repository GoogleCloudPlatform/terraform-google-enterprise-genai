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

  composer_roles = [
    "roles/composer.worker",
    "projects/${var.project_id}/roles/composerServiceAccountGCS", // Cloud Storage
    "projects/${var.project_id}/roles/composerServiceAccountBQ",  // BigQuery
    "projects/${var.project_id}/roles/composerServiceAccountBQ",  // Vertex AI
  ]

  compute_sa_roles = [
    "roles/bigquery.admin",
    "roles/dataflow.admin",
    "roles/dataflow.worker",
    "roles/storage.admin",
    "roles/aiplatform.admin",
  ]

  cloudbuild_roles = [
    "roles/aiplatform.admin",
    "roles/artifactregistry.admin",
    "roles/bigquery.admin",
    "roles/cloudbuild.connectionAdmin",
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

  service_agent_apis = [
    "aiplatform.googleapis.com",        // service-PROJECT_NUMBER@gcp-sa-aiplatform.iam.gserviceaccount.com
    "artifactregistry.googleapis.com",  // service-PROJECT_NUMBER@gcp-sa-artifactregistry.iam.gserviceaccount.com
    "bigquery.googleapis.com",          // bq-PROJECT_NUMBER@bigquery-encryption.iam.gserviceaccount.com
    "cloudkms.googleapis.com",          // service-PROJECT_NUMBER@gcp-sa-cloudkms.iam.gserviceaccount.com
    "composer.googleapis.com",          // service-PROJECT_NUMBER@cloudcomposer-accounts.iam.gserviceaccount.com
    "compute.googleapis.com",           // service-PROJECT_NUMBER@compute-system.iam.gserviceaccount.com
    "container.googleapis.com",         // service-PROJECT_NUMBER@container-engine-robot.iam.gserviceaccount.com
    "containerregistry.googleapis.com", // service-PROJECT_NUMBER@containerregistry.iam.gserviceaccount.com
    "dataflow.googleapis.com",          // service-PROJECT_NUMBER@dataflow-service-producer-prod.iam.gserviceaccount.com
    "dataform.googleapis.com",          // service-PROJECT_NUMBER@gcp-sa-dataform.iam.gserviceaccount.com
    "notebooks.googleapis.com",         // service-PROJECT_NUMBER@gcp-sa-notebooks.iam.gserviceaccount.com
    "pubsub.googleapis.com",            // service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com
    "secretmanager.googleapis.com",     // service-PROJECT_NUMBER@gcp-sa-secretmanager.iam.gserviceaccount.com
    "storage.googleapis.com",           // service-PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com
  ]

  service_agents = [
    "service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com",              // aiplatform.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",        // artifactregistry.googleapis.com
    "bq-${data.google_project.project.number}@bigquery-encryption.iam.gserviceaccount.com",                 // bigquery.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-cloudkms.iam.gserviceaccount.com",                // cloudkms.googleapis.com
    "service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",         // composer.googleapis.com
    "service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",                 // compute.googleapis.com
    "service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",         // container.googleapis.com
    "service-${data.google_project.project.number}@containerregistry.iam.gserviceaccount.com",              // containerregistry.googleapis.com
    "service-${data.google_project.project.number}@dataflow-service-producer-prod.iam.gserviceaccount.com", // dataflow.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com",                // dataform.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-notebooks.iam.gserviceaccount.com",               // notebooks.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com",                  // pubsub.googleapis.com
    "service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com",           // secretmanager.googleapis.com
    "service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com",            // storage.googleapis.com
  ]

  aiplatform_non_prod_sa = [
    "serviceAccount:service-${var.non_production_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com",
    "serviceAccount:service-${var.non_production_project_number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
  ]

  aiplatform_prod_sa = [
    "serviceAccount:service-${var.production_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com",
    "serviceAccount:service-${var.production_project_number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
  ]

  service_agent_key_binding = flatten([
    for r, k in var.kms_keys : [
      for sa in local.service_agents : { region = r, email = sa, key = k }
    ]
  ])

}

################################
### Composer Service Account ###
################################
resource "google_service_account" "composer" {
  account_id   = format("%s-%s-%s", var.service_account_prefix, var.environment_code, "composer")
  display_name = "${title(var.env)} Composer Service Account"
  description  = "Service account to be used by Cloud Composer"
  project      = var.project_id
}

resource "google_project_iam_member" "composer_project_iam" {
  for_each = toset(local.composer_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_kms_crypto_key_iam_member" "composer_kms_key_binding" {
  for_each      = var.kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_kms_crypto_key_iam_member" "composer_kms_key_binding_non_prod" {
  for_each      = { for k, v in var.kms_keys : k => v if var.env == "non-production" }
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.production_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "composer_service_agent" {
  provider           = google-beta
  service_account_id = google_service_account.composer.id
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_non_production" {
  count = var.env == "non-production" ? 1 : 0
  # provider           = google-beta
  service_account_id = data.google_service_account.non-production.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.production_project_number}-compute@developer.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_production" {
  count = var.env == "production" ? 1 : 0
  # provider           = google-beta
  service_account_id = data.google_service_account.production.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.non_production_project_number}-compute@developer.gserviceaccount.com"
}

######################
### Service Agents ###
######################
resource "google_project_service_identity" "service_agent" {
  provider = google-beta
  for_each = toset(local.service_agent_apis)

  project = var.project_id
  service = each.value
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [google_project_service_identity.service_agent]
}

resource "google_kms_crypto_key_iam_member" "service_agent_kms_key_binding" {
  for_each = { for k in local.service_agent_key_binding : "${k.email}-${k.region}" => k }

  crypto_key_id = each.value.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

###############################
# Service Catalog & Pipelines #
###############################
resource "google_project_iam_member" "cloud_build" {
  for_each = { for k, v in toset(local.cloudbuild_roles) : k => v if var.env == "development" || var.env == "non-production" }
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "bq_pipeline_prod" {
  for_each = { for k, v in toset(local.aiplatform_non_prod_sa) : k => v if var.env == "production" }
  provider = google-beta
  project  = var.project_id
  member   = each.key
  role     = "roles/bigquery.dataViewer"
}

resource "google_project_iam_member" "bq_pipeline_prod_vertex_admin" {
  count    = var.env == "production" ? 1 : 0
  provider = google-beta
  project  = var.project_id
  member   = "serviceAccount:service-${var.non_production_project_number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com"
  role     = "roles/aiplatform.admin"
}

resource "google_project_iam_member" "get_iam_policy_prod" {
  count    = var.env == "production" ? 1 : 0
  provider = google-beta
  project  = var.project_id
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
  role     = "roles/iam.serviceAccountViewer"
}

resource "google_project_iam_member" "bq_pipeline_non_prod" {
  for_each = { for k, v in toset(local.aiplatform_prod_sa) : k => v if var.env == "non-production" }
  provider = google-beta
  project  = var.project_id
  member   = each.key
  role     = "roles/bigquery.dataViewer"
}

resource "google_project_iam_member" "monitoring" {
  count   = var.env == "non-production" ? 1 : 0
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:service-${var.production_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_roles" {
  for_each = toset(local.compute_sa_roles)
  provider = google-beta
  project  = var.project_id
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role     = each.key
}

########################
#       Notebooks      #
########################

resource "google_project_iam_member" "compute" {
  count   = var.env == "development" ? 1 : 0
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

########################
#   Bucket Access      #
########################

resource "google_storage_bucket_iam_member" "prod_access" {
  count  = var.env == "non-production" ? 1 : 0
  bucket = join("-", [var.gcs_bucket_prefix, data.google_project.project.labels.env_code, var.bucket_name])
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${var.production_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"

  depends_on = [module.bucket]
}
