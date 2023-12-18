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

resource "random_string" "bucket_name" {
  length  = 4
  upper   = false
  numeric = true
  lower   = true
  special = false
}

resource "google_storage_bucket" "bucket" {
  location                    = var.region
  name                        = "${var.gcs_bucket_prefix}-${var.project_id}-${lower(var.region)}-svc-ctlg-${random_string.bucket_name.result}"
  project                     = var.project_id
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = data.google_kms_crypto_key.key.id
  }
  versioning {
    enabled = true
  }
}

resource "google_cloudbuild_trigger" "zip_files" {
  name     = "zip-tf-files-trigger"
  project  = var.project_id
  location = var.region

  repository_event_config {
    repository = var.cloudbuild_repo_id
    push {
      branch = "^main$"
    }
  }
  build {
    step {
      id         = "find-folders-affected-in-push"
      name       = "gcr.io/cloud-builders/git"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        COMMIT_SHA=$(git rev-parse HEAD)
        LAST_COMMIT_SHA=$(git rev-parse HEAD^1)

        CHANGED_FILES=$(git diff --name-only $LAST_COMMIT_SHA $COMMIT_SHA)

        CHANGED_FOLDERS=$(echo "$CHANGED_FILES" | awk -F/ '{print $1}' | sort -u)

        for folder in $CHANGED_FOLDERS; do
          (cd $folder && zip -r "/workspace/$folder.zip" *.tf)
        done
      EOT
      ]
    }
    step {
      id   = "push-to-bucket"
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "/workspace/*.zip", "gs://${google_storage_bucket.bucket.name}/modules/"]
    }
  }
}

