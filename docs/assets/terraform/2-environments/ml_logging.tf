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

data "google_storage_project_service_account" "gcs_logging_account" {
  project = module.env_logs.project_id
}

/******************************************
  Project for Environment Logging
*****************************************/

module "env_logs" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.0"

  random_project_id        = true
  random_project_id_length = 4
  default_service_account  = "deprivilege"
  name                     = "${local.project_prefix}-${var.environment_code}-logging"
  org_id                   = local.org_id
  billing_account          = local.billing_account
  folder_id                = google_folder.env.id
  activate_apis            = ["logging.googleapis.com", "billingbudgets.googleapis.com", "storage.googleapis.com"]

  labels = {
    environment       = var.env
    application_name  = "env-logging"
    billing_code      = "1234"
    primary_contact   = "example1"
    secondary_contact = "example2"
    business_code     = "abcd"
    env_code          = var.environment_code
  }
  budget_alert_pubsub_topic   = var.project_budget.logging_alert_pubsub_topic
  budget_alert_spent_percents = var.project_budget.logging_alert_spent_percents
  budget_amount               = var.project_budget.logging_budget_amount
  budget_alert_spend_basis    = var.project_budget.logging_budget_alert_spend_basis

}

// Create Bucket for this project
resource "google_storage_bucket" "log_bucket" {
  name                        = "${var.gcs_bucket_prefix}-${module.env_logs.project_id}"
  location                    = var.gcs_logging_bucket_location
  project                     = module.env_logs.project_id
  uniform_bucket_level_access = true

  dynamic "retention_policy" {
    for_each = var.gcs_logging_retention_period != null ? [var.gcs_logging_retention_period] : []
    content {
      is_locked        = var.gcs_logging_retention_period.is_locked
      retention_period = var.gcs_logging_retention_period.retention_period_days * 24 * 60 * 60
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key_iam_member.gcs_logging_key.crypto_key_id #module.kms_keyring.keys_by_region[var.gcs_logging_bucket_location][local.logging_key_name]
  }
}

/******************************************
  Logging Bucket - IAM
*****************************************/
# resource "google_storage_bucket_iam_member" "bucket_logging" {
#   bucket = google_storage_bucket.log_bucket.name
#   role   = "roles/storage.objectCreator"
#   member = "group:cloud-storage-analytics@google.com"
# }

resource "google_kms_crypto_key_iam_member" "gcs_logging_key" {
  crypto_key_id = module.kms_keyring.keys_by_region[var.gcs_logging_bucket_location][local.logging_key_name]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_logging_account.email_address}"
}
