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

data "google_project" "ml_project" {
  project_id = var.machine_learning_project
}

resource "google_workbench_instance" "instance" {
  disable_proxy_access = false
  instance_owners      = []
  location             = var.instance_location
  name                 = var.machine_name
  project              = var.machine_learning_project

  gce_setup {
    service_accounts {
      email = google_service_account.notebook_runner.email
    }
    disable_public_ip = true
    machine_type      = var.machine_type
    metadata = {
      "disable-mixer"              = "false"
      "notebook-disable-downloads" = "true"
      "notebook-disable-root"      = "true"
      "notebook-disable-terminal"  = "true"
      "notebook-upgrade-schedule"  = "00 19 * * MON"
      "report-dns-resolution"      = "true"
      "report-event-health"        = "true"
      "terraform"                  = "true"
    }
    tags = [
      "egress-internet",
    ]
    boot_disk {
      disk_encryption = "CMEK"
      disk_size_gb    = "150"
      disk_type       = "PD_SSD"
      kms_key         = var.kms_key
    }
    data_disks {
      disk_encryption = "CMEK"
      disk_size_gb    = "150"
      disk_type       = "PD_SSD"
      kms_key         = var.kms_key
    }
    network_interfaces {
      network = var.network
      subnet  = var.subnet
    }
    vm_image {
      family  = "workbench-instances"
      project = "cloud-notebooks-managed"
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_storage_bucket" "vector_search_bucket" {
  name                        = "vector-search-${random_string.suffix.result}"
  location                    = var.vector_search_bucket_location
  storage_class               = "REGIONAL"
  project                     = var.machine_learning_project
  uniform_bucket_level_access = true
}

resource "google_compute_address" "vector_search_static_ip" {
  name         = var.vector_search_address_name
  region       = var.vector_search_ip_region
  subnetwork   = var.subnet
  project      = var.vector_search_vpc_project
  address_type = "INTERNAL"
}

resource "google_service_account" "notebook_runner" {
  account_id   = var.service_account_name
  display_name = "RAG Notebook Runner Service Account"
  project      = var.machine_learning_project
}

resource "google_project_iam_member" "notebook_runner_roles" {
  for_each = toset([
    "roles/aiplatform.user"
  ])
  project = var.machine_learning_project
  role    = each.key
  member  = google_service_account.notebook_runner.member
}

resource "google_storage_bucket_iam_member" "notebook_runner_bucket_admin" {
  bucket = google_storage_bucket.vector_search_bucket.name
  role   = "roles/storage.admin"
  member = google_service_account.notebook_runner.member
}

# Service Agent Role Assignment - Allows creation of workbench instance when using var.kms_key

resource "google_kms_crypto_key_iam_member" "service_agent_kms_key_binding" {
  for_each = toset([
    "serviceAccount:service-${data.google_project.ml_project.number}@compute-system.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.ml_project.number}@gcp-sa-notebooks.iam.gserviceaccount.com"
  ])
  crypto_key_id = var.kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}
