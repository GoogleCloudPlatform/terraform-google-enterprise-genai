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

# resource "google_project_service_identity" "storage_agent" {
#   provider = google-beta

#   project = var.project_id
#   service = "storage.googleapis.com"
# }
# resource "google_kms_crypto_key_iam_member" "storage-kms-key-binding" {
#   crypto_key_id = var.kms_crypto_key
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:${google_project_service_identity.storage_agent.email}"
# }

resource "random_string" "bucket_name" {
  length  = 4
  upper   = false
  numeric = true
  lower   = true
  special = false
}

resource "google_storage_bucket" "bucket" {
  location                    = var.region
  name                        = "${var.gcs_bucket_prefix}-${var.project_id}-${lower(var.region)}-${random_string.bucket_name.result}"
  project                     = var.project_id
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = var.kms_crypto_key
  }
  versioning {
    enabled = true
  }
  logging {
    log_bucket = var.log_bucket
  }

}

resource "google_storage_bucket_iam_member" "bucket_role" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  member = google_service_account.trigger_sa.member
}
resource "google_sourcerepo_repository_iam_member" "read" {
  project    = var.project_id
  repository = var.name
  role       = "roles/viewer"
  member     = "serviceAccount:${var.tf_service_catalog_sa_email}"
}

resource "google_service_account" "trigger_sa" {
  account_id   = var.trigger_sa_id
  display_name = "Service Catalog Pipeline Account"
  project      = var.project_id
}

resource "google_service_account_iam_member" "impersonate" {
  service_account_id = google_service_account.trigger_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = local.current_member
}

resource "random_string" "suffix" {
  length  = 10
  special = false
  upper   = false
}

resource "google_storage_bucket" "cloud_build_logs" {
  name                        = "svc-catalog-pipeline-logs-${random_string.suffix.result}"
  storage_class               = "REGIONAL"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = var.kms_crypto_key
  }
}

resource "google_sourcerepo_repository_iam_member" "repo_reader" {
  repository = data.google_sourcerepo_repository.artifacts_repo.id
  role       = "roles/source.reader"
  member     = google_service_account.trigger_sa.member
}

resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.cloud_build_logs.name
  role   = "roles/storage.admin"
  member = google_service_account.trigger_sa.member
}

resource "google_cloudbuild_trigger" "zip_files" {
  name     = "zip-tf-files-trigger"
  project  = var.project_id
  location = var.region

  trigger_template {
    branch_name = "^main$"
    repo_name   = var.name
  }

  service_account = google_service_account.trigger_sa.id
  build {
    timeout     = "1800s"
    logs_bucket = google_storage_bucket.bucket.name
    step {
      id         = "unshallow"
      name       = "gcr.io/cloud-builders/git"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        "git fetch --unshallow"
      ]

    }
    step {
      id         = "find-folders-affected-in-push"
      name       = "gcr.io/cloud-builders/git"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        changed_files=$(git diff $${COMMIT_SHA}^1 --name-only -r)
        changed_folders=$(echo "$changed_files" | awk -F/ '{print $2}' | sort | uniq )

        for folder in $changed_folders; do
          if [[ "$folder" != *.* ]]; then
            echo "Found change in folder: $folder"
            (cd modules/$folder && find . -type f -name '*.tf' -exec tar -cvzPf "/workspace/$folder.tar.gz" {} +)
          fi
        done
      EOT
      ]
    }
    step {
      id   = "push-to-bucket"
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "/workspace/*.tar.gz", "gs://${google_storage_bucket.bucket.name}/modules/"]
    }
  }

  depends_on = [google_service_account_iam_member.impersonate]
}
