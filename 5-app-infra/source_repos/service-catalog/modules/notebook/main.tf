/**
 * Copyright 2023 Google LLC
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

resource "google_workbench_instance" "instance" {
  name     = var.name
  location = var.location

  gce_setup {
    machine_type = var.machine_type

    dynamic "accelerator_configs" {
      for_each = var.install_gpu_driver == true ? [1] : []
      content {
        type       = var.accelerator_type
        core_count = var.core_count
      }
    }
    disable_public_ip = true


    dynamic "vm_image" {
      for_each = var.image_family != "" ? [1] : []
      content {
        project = var.image_project
        family  = var.image_family
      }
    }

    dynamic "vm_image" {
      for_each = var.image_name != "" ? [1] : []
      content {
        project = var.image_project
        name    = var.image_name
      }
    }

    boot_disk {
      disk_type       = var.boot_disk_type
      disk_size_gb    = var.boot_disk_size_gb
      disk_encryption = "CMEK"
      kms_key         = data.google_kms_crypto_key.key.id
    }

    data_disks {
      disk_size_gb    = var.data_disk_size_gb
      disk_type       = var.data_disk_type
      disk_encryption = "CMEK"
      kms_key         = data.google_kms_crypto_key.key.id
    }

    enable_ip_forwarding = false

    tags = var.tags

    network_interfaces {
      network  = data.google_compute_network.shared_vpc.id
      subnet   = data.google_compute_subnetwork.subnet.id
      nic_type = "GVNIC"
    }

    metadata = {
      notebook-disable-downloads = "true"
      notebook-disable-root      = "true"
      notebook-disable-terminal  = "true"
      notebook-upgrade-schedule  = "00 19 * * MON"
      # disable-mixer              = "${var.dataproc_kernel_access ? false : true}"
      disable-mixer         = "true" // Enable access to Dataproc kernels
      report-dns-resolution = "true"
      report-event-health   = "true"
      terraform             = "true"
    }
  }

  instance_owners = var.instance_owners

  disable_proxy_access = var.disable_proxy_access

  labels = {
    environment  = data.google_project.project.labels.environment
    boundry_code = var.boundry_code
  }
}
