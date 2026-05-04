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
  seed_project_name             = var.seed_project_name != "" ? var.seed_project_name : "prj-seed-${random_id.project_id_suffix.hex}"
  kms_project_name              = var.kms_project_name != "" ? var.kms_project_name : "prj-kms-${random_id.project_id_suffix.hex}"
  logging_project_name          = var.logging_project_name != "" ? var.logging_project_name : "prj-logging-${random_id.project_id_suffix.hex}"
  machine_learning_project_name = var.machine_learning_project_name != "" ? var.machine_learning_project_name : "prj-machine-learning-${random_id.project_id_suffix.hex}"
  service_catalog_project_name  = var.service_catalog_project_name != "" ? var.service_catalog_project_name : "prj-service-catalog-${random_id.project_id_suffix.hex}"
  artifact_publish_project_name = var.artifact_publish_project_name != "" ? var.artifact_publish_project_name : "prj-publish-artifacts-${random_id.project_id_suffix.hex}"
  bucket_name                   = format("%s-%s", "tfstate", random_id.project_id_suffix.hex)

  terraform_sa_project_roles = [
    "roles/storage.admin",
    "roles/cloudkms.admin",
  ]

  terraform_state_kms_key = module.kms.keys["${var.project_prefix}-key"]
}

resource "random_id" "project_id_suffix" {
  byte_length = 2
}

/******************************************
  Project for state bucket
*****************************************/

module "seed_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.seed_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["cloudkms.googleapis.com", "serviceusage.googleapis.com", "iamcredentials.googleapis.com", "storage.googleapis.com"]
}

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.0"

  project_id          = module.seed_project.project_id
  location            = var.default_region
  keyring             = "${var.project_prefix}-keyring"
  keys                = ["${var.project_prefix}-key"]
  key_rotation_period = "7776000s"

  prevent_destroy = var.kms_prevent_destroy
}

resource "google_storage_bucket" "terraform_state" {
  project                     = module.seed_project.project_id
  name                        = local.bucket_name
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.encrypt_gcs_bucket_tfstate ? ["encryption"] : []
    content {
      default_kms_key_name = local.terraform_state_kms_key
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.terraform_state_gcs_kms]
}

data "google_storage_project_service_account" "gcs_account" {
  project = module.seed_project.project_id
}

resource "google_kms_crypto_key_iam_member" "terraform_state_gcs_kms" {
  crypto_key_id = local.terraform_state_kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_project_iam_member" "terraform_sa_project_roles" {
  for_each = toset(local.terraform_sa_project_roles)

  project = module.seed_project.project_id
  role    = each.value
  member  = "serviceAccount:${var.terraform_service_account}"
}

/******************************************
  Project for KMS
*****************************************/

module "kms_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.kms_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["logging.googleapis.com", "cloudkms.googleapis.com", "billingbudgets.googleapis.com"]
}

/******************************************
  Project for Logs Storage
*****************************************/

module "logging_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.logging_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["logging.googleapis.com", "bigquery.googleapis.com", "billingbudgets.googleapis.com"]
}


/******************************************
  Project Machine Learning
*****************************************/

module "machine_learning_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.machine_learning_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "keep"
  deletion_policy         = var.project_deletion_policy

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
}


/******************************************
  Project for Publish Artifacts
*****************************************/

module "artifact_publish_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.artifact_publish_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy

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
}

/******************************************
  Project Service Catalog
*****************************************/

module "service_catalog_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.service_catalog_project_name
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy

  activate_apis = [
    "logging.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
}
