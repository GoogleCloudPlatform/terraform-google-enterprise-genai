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


// clean this up
# resource "google_project_service_identity" "agent" {
#   provider = google-beta

#   project = var.project_id
#   service = "secretmanager.googleapis.com"
# }

resource "google_project_service_identity" "artifact_registry_agent" {
  provider = google-beta

  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

# resource "google_kms_crypto_key_iam_member" "kms-key-binding" {
#   crypto_key_id = data.google_kms_crypto_key.key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:${google_project_service_identity.agent.email}"
# }

resource "google_kms_crypto_key_iam_member" "artifact-kms-key-binding" {
  crypto_key_id = data.google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.artifact_registry_agent.email}"
}

# resource "google_secret_manager_secret" "github_secret" {
#   project   = var.project_id
#   secret_id = "github-api-token"
#   replication {
#     user_managed {
#       replicas {
#         location = var.region
#         customer_managed_encryption {
#           kms_key_name = data.google_kms_crypto_key.key.id
#         }
#       }
#     }
#   }
# }

# resource "google_secret_manager_secret_version" "github_secret_version" {
#   secret                = google_secret_manager_secret.github_secret.id
#   is_secret_data_base64 = true
#   secret_data           = base64encode(var.github_api_token)
# }

# data "google_iam_policy" "serviceagent_secretAccessor" {
#   binding {
#     role    = "roles/secretmanager.secretAccessor"
#     members = ["serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
#   }
# }

# resource "google_secret_manager_secret_iam_policy" "policy" {
#   project     = google_secret_manager_secret.github_secret.project
#   secret_id   = google_secret_manager_secret.github_secret.secret_id
#   policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
# }

# resource "google_cloudbuildv2_connection" "docker_repo_connection" {
#   provider = google-beta
#   project  = data.google_project.project.project_id
#   location = var.region
#   name     = "${var.github_name_prefix}-connection"

#   github_config {
#     app_installation_id = var.github_app_installation_id
#     authorizer_credential {
#       oauth_token_secret_version = google_secret_manager_secret_version.github_secret_version.id
#     }
#   }
#   depends_on = [google_secret_manager_secret_iam_policy.policy]
# }

# resource "google_cloudbuildv2_repository" "docker_repo" {
#   provider          = google-beta
#   project           = data.google_project.project.project_id
#   location          = var.region
#   name              = "${var.github_name_prefix}-repo"
#   parent_connection = google_cloudbuildv2_connection.docker_repo_connection.id
#   remote_uri        = var.github_remote_uri
# }
resource "google_artifact_registry_repository" "my-repo" {
  provider               = google-beta
  location               = var.region
  repository_id          = local.name_var
  description            = var.description
  format                 = var.format
  cleanup_policy_dry_run = var.cleanup_policy_dry_run
  project                = data.google_project.project.project_id

  #Customer Managed Encryption Keys
  #Control ID: COM-CO-2.3
  #NIST 800-53: SC-12 SC-13
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1

  kms_key_name = data.google_kms_crypto_key.key.id

  #Cleanup policy
  #Control ID:  AR-CO-6.1
  #NIST 800-53: SI-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = condition.value[0].tag_state
          tag_prefixes          = condition.value[0].tag_prefixes
          package_name_prefixes = condition.value[0].package_name_prefixes
          older_than            = condition.value[0].older_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = most_recent_versions.value[0].package_name_prefixes
          keep_count            = most_recent_versions.value[0].keep_count
        }
      }
    }
  }
  depends_on = [
    google_kms_crypto_key_iam_member.artifact-kms-key-binding,

  ]
}

# resource "google_service_account" "trigger_sa" {
#   account_id  = "sa-apps-${local.name_var}"
#   project     = var.project_id
#   description = "Service account for Cloud Build in ${var.project_id}"
# }

# resource "google_service_account_iam_member" "trigger_sa_impersonate" {
#   service_account_id = google_service_account.trigger_sa.id
#   role               = "roles/iam.serviceAccountTokenCreator"
#   member             = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
# }

resource "google_artifact_registry_repository_iam_member" "project" {
  for_each   = toset(local.trigger_sa_roles)
  project    = var.project_id
  repository = google_artifact_registry_repository.my-repo.name
  location   = var.region
  role       = each.key
  # member     = "serviceAccount:${google_service_account.trigger_sa.email}"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_cloudbuild_trigger" "docker_build" {
  name     = "docker-build"
  project  = var.project_id
  location = var.region

  # service_account = google_service_account.trigger_sa.id
  repository_event_config {
    repository = var.cloudbuild_repo_id
    push {
      branch = "^main$"
    }
  }
  build {
    step {
      id         = "select-folder"
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        commit_message=$(git log --format=%B -n 1 $COMMIT_SHA)
        if [[ $commit_message == *"build@"* ]]; then
            docker_image=$${commit_message##*build@}
            docker_image=$${docker_image%%[[:space:]]*}
            if [ -z "$docker_image" ]; then
            echo "Error: Invalid commit message format. Unable to extract Docker image name."
            echo "commit message should be: 'build@[image-name:tag]'"
            exit 1
            fi
        for folder in $(ls -d images/*); do
            folder_name=$(basename $folder)
            if [ "$folder_name" == "$docker_image" ]; then
            export docker_folder=$folder_name
            echo "Found docker folder:"
            echo $docker_folder
            env | grep "^docker_" > /workspace/build_vars
            exit 0
            fi
        done
        echo "Error: No matching folder found for Docker image '$docker_image'."
        exit 1
      fi
        EOT
      ]
    }
    step {
      id         = "build-image"
      wait_for   = ["select-folder"]
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        source /workspace/build_vars
        docker build -t gcr.io/$PROJECT_ID/$docker_folder images/$docker_folder
        EOT
      ]
    }

    step {
      id         = "push-image"
      wait_for   = ["select-folder", "build-image"]
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
        source /workspace/build_vars
        docker push gcr.io/$PROJECT_ID/$docker_folder
        EOT
      ]
    }
  }
}
