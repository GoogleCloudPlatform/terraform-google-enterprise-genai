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

# resource "google_project_service_identity" "storage_agent" {
#   provider = google-beta

#   project = var.project_id
#   service = "storage.googleapis.com"
# }
# resource "google_kms_crypto_key_iam_member" "storage-kms-key-binding" {
#   crypto_key_id = data.google_kms_crypto_key.key.id
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
    default_kms_key_name = data.google_kms_crypto_key.key.id
  }
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "bucket_role" {
  for_each = { for gcs in local.bucket_roles : "${gcs.role}-${gcs.acct}" => gcs }
  bucket   = google_storage_bucket.bucket.name
  role     = each.value.role
  member   = each.value.acct
}

resource "google_sourcerepo_repository" "service_catalog" {
  project = var.project_id
  name    = var.name
}

resource "google_sourcerepo_repository_iam_member" "read" {
  project    = var.project_id
  repository = google_sourcerepo_repository.service_catalog.name
  role       = "roles/viewer"
  member     = "serviceAccount:${var.tf_service_catalog_sa_email}"

  depends_on = [google_sourcerepo_repository.service_catalog]
}

resource "google_cloudbuild_trigger" "zip_files" {
  name     = "zip-tf-files-trigger"
  project  = var.project_id
  location = var.region

  # repository_event_config {
  #   repository = var.cloudbuild_repo_id
  #   push {
  #     branch = "^main$"
  #   }
  # }

  trigger_template {
    branch_name = "^main$"
    repo_name   = google_sourcerepo_repository.service_catalog.name
  }

  build {
    # step {
    #   id         = "unshallow"
    #   name       = "gcr.io/cloud-builders/git"
    #   secret_env = ["token"]
    #   entrypoint = "/bin/bash"
    #   args = [
    #     "-c",
    #     "git fetch --unshallow https://$token@${local.github_repository}"
    #   ]

    # }
    step {
      id         = "unshallow"
      name       = "gcr.io/cloud-builders/git"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        "git fetch --unshallow"
      ]

    }
    # available_secrets {
    #   secret_manager {
    #     env          = "token"
    #     version_name = var.secret_version_name
    #   }
    # }
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
          echo "Found change in folder: $folder"
          (cd modules/$folder && find . -type f -name '*.tf' -exec tar -cvzPf "/workspace/$folder.tar.gz" {} +)
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
}

