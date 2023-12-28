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

# resource "google_project_service_identity" "agent" {
#   provider = google-beta

#   project = var.project_id
#   service = "secretmanager.googleapis.com"
# }

# resource "google_kms_crypto_key_iam_member" "kms-key-binding" {
#   crypto_key_id = data.google_kms_crypto_key.key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:${google_project_service_identity.agent.email}"
# }
resource "google_secret_manager_secret" "github_secret" {
  project   = var.project_id
  secret_id = "github-api-token"
  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = data.google_kms_crypto_key.key.id
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "github_secret_version" {
  secret                = google_secret_manager_secret.github_secret.id
  is_secret_data_base64 = true
  secret_data           = base64encode(var.github_api_token)
}

data "google_iam_policy" "serviceagent_secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = google_secret_manager_secret.github_secret.project
  secret_id   = google_secret_manager_secret.github_secret.secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

resource "google_cloudbuildv2_connection" "repo_connect" {
  provider = google-beta
  project  = data.google_project.project.project_id
  location = var.region
  name     = "${var.github_name_prefix}-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_secret_version.id
    }
  }
  depends_on = [google_secret_manager_secret_iam_policy.policy]
}

resource "google_cloudbuildv2_repository" "repo" {
  provider          = google-beta
  project           = data.google_project.project.project_id
  location          = var.region
  name              = "${var.github_name_prefix}-repo"
  parent_connection = google_cloudbuildv2_connection.repo_connect.id
  remote_uri        = var.github_remote_uri
}

###### Added in but not used yet ########
resource "google_service_account" "trigger_sa" {
  account_id  = "sa-apps-${local.name_var}"
  project     = var.project_id
  description = "Service account for Cloud Build in ${var.project_id}"
}
###### Added in but not used yet ########
resource "google_service_account_iam_member" "trigger_sa_impersonate" {
  service_account_id = google_service_account.trigger_sa.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
