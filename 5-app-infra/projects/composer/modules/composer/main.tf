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

# resource "random_string" "bucket_name" {
#   length  = 4
#   upper   = false
#   numeric = true
#   lower   = true
#   special = false
# }

# resource "google_storage_bucket" "bucket" {
#   location                    = var.region
#   name                        = "${var.gcs_bucket_prefix}-${var.project_id}-${lower(var.region)}-${random_string.bucket_name.result}"
#   project                     = var.project_id
#   uniform_bucket_level_access = true

#   encryption {
#     default_kms_key_name = data.google_kms_crypto_key.key.id
#   }
#   versioning {
#     enabled = true
#   }
# }

resource "random_shuffle" "zones" {
  input        = local.zones[var.region]
  result_count = 1
}

# Highly opionated deployment of composer.
#
# Depending on the region this module sets specific IPs and makes sure the cluster
# is private.


# // Grab Service Agent for Artifact Registry

# locals {
#   service_agents = [
#     "artifactregistry.googleapis.com",
#     "pubsub.googleapis.com",
#     "storage.googleapis.com",
#     "secretmanager.googleapis.com",
#   ]

#   kms_secret_sa_accounts = [
#     "serviceAccount:${google_service_account.composer.email}",
#     "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
#     "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
#     "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",
#     "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com",
#     "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com",
#     "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",
#   ]
# }
# resource "google_project_service_identity" "service_agents" {
#   for_each = toset(local.service_agents)
#   provider = google-beta
#   project  = data.google_project.project.project_id
#   service  = each.key
# }

# resource "google_kms_crypto_key_iam_member" "kms-secret-binding" {
#   count         = length(local.kms_secret_sa_accounts)
#   crypto_key_id = data.google_kms_crypto_key.key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = local.kms_secret_sa_accounts[count.index]

# }

resource "google_composer_environment" "cluster" {
  provider = google-beta

  project = data.google_project.project.project_id
  name    = local.name_var
  region  = var.region
  labels  = local.labels

  config {
    node_config {
      network         = "projects/${data.google_project.project.project_id}/global/networks/${local.network_name}"
      subnetwork      = "projects/${data.google_project.project.project_id}/regions/${var.region}/subnetworks/${local.subnetwork}"
      service_account = "composer@${data.google_project.project.project_id}.iam.gserviceaccount.com"
      tags            = local.tags

      ip_allocation_policy {
        cluster_secondary_range_name  = local.cluster_secondary_range_name
        services_secondary_range_name = local.services_secondary_range_name
      }
    }

    private_environment_config {
      enable_private_endpoint   = true
      master_ipv4_cidr_block    = var.region == "us-central1" ? "192.168.1.0/28" : "192.168.0.0/28"
      cloud_sql_ipv4_cidr_block = var.region == "us-central1" ? "192.168.5.0/24" : "192.168.4.0/24"
    }

    maintenance_window {
      start_time = var.maintenance_window.start_time
      end_time   = var.maintenance_window.end_time
      recurrence = var.maintenance_window.recurrence
    }

    dynamic "web_server_network_access_control" {
      for_each = var.web_server_allowed_ip_ranges == null ? [] : [1]
      content {
        dynamic "allowed_ip_range" {
          for_each = var.web_server_allowed_ip_ranges
          content {
            value       = allowed_ip_range.value.value
            description = allowed_ip_range.value.description
          }
        }
      }
    }

    # allow the capability to set software overrides
    dynamic "software_config" {
      for_each = var.python_version != "" ? [
        {
          airflow_config_overrides = var.airflow_config_overrides
          env_variables            = var.env_variables
          image_version            = var.image_version
          pypi_packages            = var.pypi_packages
      }] : []
      content {
        airflow_config_overrides = software_config.value["airflow_config_overrides"]
        env_variables            = software_config.value["env_variables"]
        image_version            = software_config.value["image_version"]
        pypi_packages            = software_config.value["pypi_packages"]
      }
    }

    encryption_config {
      kms_key_name = data.google_kms_crypto_key.key.id
    }
  }

  depends_on = [
    module.vpc
  ]
}

# resource "google_storage_bucket_iam_member" "bucket_member" {
#   bucket = google_storage_bucket.bucket.name
#   role   = "roles/storage.admin"
#   member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
# }

resource "google_cloudbuild_trigger" "zip_files" {
  name     = "zip-tf-files-trigger"
  project  = var.project_id
  location = var.region

  repository_event_config {
    repository = var.cloudbuild_repo_id
    push {
      branch = "^${var.environment}$"
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
        version_name = var.secret_version_name
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
}

