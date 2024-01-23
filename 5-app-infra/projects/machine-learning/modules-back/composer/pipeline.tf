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

resource "google_secret_manager_secret" "github_secret" {
  project   = data.google_project.project.project_id
  secret_id = "github-api-token"

  #Set up Automatic Rotation of Secrets
  #Control ID: SM-CO-6.2
  #NIST 800-53: SC-12 SC-13

  # how rotation be used with the GitHub token?
  # rotation {
  #   next_rotation_time = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "720h"))
  #   rotation_period    = "43200s"
  # }

  #Automatic Secret Replication
  #Control ID: SM-CO-6.1
  #NIST 800-53: SC-12 SC-13
  replication {
    user_managed {
      replicas {
        location = var.region

        #Customer Managed Encryption Keys
        #Control ID: COM-CO-2.3
        #NIST 800-53: SC-12 SC-13
        #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1
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
  account_id  = "sa-apps-${local.sa_name}"
  project     = data.google_project.project.project_id
  description = "Service account for Cloud Build in ${data.google_project.project.project_id}"
}
###### Added in but not used yet ########
resource "google_service_account_iam_member" "trigger_sa_impersonate" {
  service_account_id = google_service_account.trigger_sa.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_cloudbuild_trigger" "zip_files" {
  name     = "zip-tf-files-trigger"
  project  = data.google_project.project.project_id
  location = var.region

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id
    push {
      branch = "^${local.labels.environment}$"
    }
  }
  build {
    step {
      id         = "unshallow"
      name       = "gcr.io/cloud-builders/git"
      secret_env = ["token"]
      entrypoint = "/bin/bash"
      args = [
        "-c",
        "git fetch --unshallow https://$token@${local.github_repository}"
      ]

    }
    available_secrets {
      secret_manager {
        env          = "token"
        version_name = google_secret_manager_secret_version.github_secret_version.name
      }
    }
    step {
      id         = "find-folders-affected-in-push"
      name       = "gcr.io/cloud-builders/gsutil"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        changed_files=$(git diff $${COMMIT_SHA}^1 --name-only -r)
        dags=$(echo "$changed_files" | xargs basename | sort | uniq )

        for dag in $dags; do
          echo "Found change in DAG: $dag"
          (cd dags && zip /workspace/$dag.zip $dag)
        done
      EOT
      ]
    }
    step {
      id   = "push-to-bucket"
      name = "gcr.io/cloud-builders/gsutil"
      args = ["cp", "/workspace/*.zip", "${google_composer_environment.cluster.config.0.dag_gcs_prefix}/"]
    }
  }

  depends_on = [google_composer_environment.cluster]
}
