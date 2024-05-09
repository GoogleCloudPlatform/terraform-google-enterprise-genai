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
  // Project's Shared VPC
  shared_vpc_host_project_id = local.restricted_host_project_id
  shared_vpc_subnets         = local.restricted_subnets_self_links

  shared_vpc_roles = [
    "roles/browser",
    "roles/compute.networkUser",
  ]

  service_identity_apis = [
    "cloudbuild.googleapis.com",
    "notebooks.googleapis.com"
  ]
}

module "machine_learning_project" {
  source = "../ml_single_project"

  org_id                             = local.org_id
  billing_account                    = local.billing_account
  folder_id                          = var.business_unit_folder
  environment                        = var.env
  vpc_type                           = "restricted"
  default_service_account            = "keep"
  shared_vpc_host_project_id         = local.shared_vpc_host_project_id
  shared_vpc_subnets                 = local.shared_vpc_subnets
  project_budget                     = var.project_budget
  project_prefix                     = local.project_prefix
  key_rings                          = local.environments_kms_key_ring
  remote_state_bucket                = var.remote_state_bucket
  vpc_service_control_attach_enabled = "true"
  vpc_service_control_perimeter_name = "accessPolicies/${local.access_context_manager_policy_id}/servicePerimeters/${local.perimeter_name}"
  vpc_service_control_sleep_duration = "60s"
  // Enabling Cloud Build Deploy to use Service Accounts during the build and give permissions to the SA.
  // The permissions will be the ones necessary for the deployment of the step 5-app-infra
  enable_cloudbuild_deploy = local.enable_cloudbuild_deploy

  // A map of Service Accounts to use on the infra pipeline (Cloud Build)
  // Where the key is the repository name ("${var.business_code}-example-app")
  app_infra_pipeline_service_accounts = local.app_infra_pipeline_service_accounts

  // Map for the roles where the key is the repository name ("${var.business_code}-example-app")
  // and the value is the list of roles that this SA need to deploy step 5-app-infra
  sa_roles = {
    "bu3-machine-learning" = [
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

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "deploymentmanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "notebooks.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
  ]

  # Metadata
  project_suffix    = "machine-learning"
  application_name  = "machine-learning"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = var.business_code
}


// Service Agents
resource "google_project_service_identity" "cloud_build" {
  provider = google-beta

  project = module.machine_learning_project.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service_identity" "notebooks" {
  provider = google-beta

  project = module.machine_learning_project.project_id
  service = "notebooks.googleapis.com"
}

resource "google_project_service_identity" "secrets" {
  provider = google-beta

  project = module.machine_learning_project.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_project_service_identity" "aiplatform" {
  provider = google-beta

  project = module.machine_learning_project.project_id
  service = "aiplatform.googleapis.com"
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [
    google_project_service_identity.cloud_build,
    google_project_service_identity.notebooks,
    google_project_service_identity.secrets,
    google_project_service_identity.aiplatform,
  ]
}

// Add cloudkms admin to sa
resource "google_kms_crypto_key_iam_member" "kms_admin" {
  for_each      = module.machine_learning_project.kms_keys
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${local.app_infra_pipeline_service_accounts["bu3-machine-learning"]}"
}

// Add crypto key viewer role to kms environment project
resource "google_project_iam_member" "cloud_build_kms_viewer" {
  project = local.environment_kms_project_id
  role    = "roles/cloudkms.viewer"
  member  = "serviceAccount:${google_project_service_identity.cloud_build.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

// Cloud Build's Service Agent permissions on Shared VPC
resource "google_project_iam_member" "cloud_build_network_user" {
  for_each = toset(local.shared_vpc_roles)
  project  = local.shared_vpc_host_project_id

  role   = each.value
  member = "serviceAccount:${google_project_service_identity.cloud_build.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

// Notebooks' Aervice Agent permissions on Shared VPC
resource "google_compute_subnetwork_iam_member" "notebook_network_user" {
  provider = google-beta
  for_each = { for nr in local.restricted_subnets_region : (nr.subnet) => nr }

  subnetwork = each.value.subnet
  role       = "roles/compute.networkUser"
  region     = each.value.region
  project    = local.shared_vpc_host_project_id
  member     = "serviceAccount:${google_project_service_identity.notebooks.email}"
}

resource "google_kms_crypto_key_iam_member" "secrets" {
  for_each = module.machine_learning_project.kms_keys

  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secrets.email}"

  depends_on = [time_sleep.wait_30_seconds]
}

// Allow machine-learning sa access to service catalog cloud source repository
resource "google_sourcerepo_repository_iam_member" "read" {
  project    = local.service_catalog_project_id
  repository = local.service_catalog_repo_name
  role       = "roles/viewer"
  member     = "serviceAccount:${local.app_infra_pipeline_service_accounts["bu3-machine-learning"]}"
}

// Add Browser Role to CloudBuild at Env Folder

resource "google_folder_iam_member" "name" {
  folder = local.env_folder_name
  role   = "roles/browser"
  member = "serviceAccount:${google_project_service_identity.cloud_build.email}"
}

// Add Artifact Registry Access to Vertex AI Agent

resource "google_project_iam_member" "access_artifacts" {
  count   = var.env == "production" ? 1 : 0
  project = local.common_artifact_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${module.machine_learning_project.project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_30_seconds]
}
