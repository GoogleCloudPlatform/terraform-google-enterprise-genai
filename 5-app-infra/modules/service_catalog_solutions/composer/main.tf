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

resource "random_shuffle" "zones" {
  input        = local.zones[var.region]
  result_count = 1
}

resource "google_composer_environment" "cluster" {
  provider = google-beta

  project = data.google_project.project.project_id
  name    = var.name
  region  = var.region
  labels  = local.labels

  config {
    node_config {
      network         = "projects/${data.google_project.project.project_id}/global/networks/${local.network_name}"
      subnetwork      = "projects/${data.google_project.project.project_id}/regions/${var.region}/subnetworks/${local.subnetwork}"
      service_account = data.google_service_account.composer.email
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
    module.vpc,
  ]
}
