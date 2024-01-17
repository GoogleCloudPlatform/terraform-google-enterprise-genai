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

/******************************************
  Monitoring - IAM
*****************************************/

resource "google_project_iam_member" "monitoring_editor" {
  project = module.monitoring_project.project_id
  role    = "roles/monitoring.editor"
  member  = "group:${var.monitoring_workspace_users}"
}

/******************************************
  Logging Bucket - IAM
*****************************************/

resource "google_storage_bucket_iam_member" "bucket_logging" {
  bucket = google_storage_bucket.log_bucket.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

data "google_storage_project_service_account" "gcs_logging_account" {
  project = module.env_logs.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_logging_key" {
  for_each      = google_kms_crypto_key.logging_keys
  crypto_key_id = google_kms_crypto_key.logging_keys[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_logging_account.email_address}"
}
