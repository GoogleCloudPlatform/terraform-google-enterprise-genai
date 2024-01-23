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

resource "google_notebooks_instance" "instance" {
  # project = ?
  name            = var.name
  location        = var.location
  machine_type    = var.machine_type
  instance_owners = var.instance_owners
  disk_encryption = "CMEK"
  kms_key         = data.google_kms_crypto_key.key.id
  # service_account        = var.service_account ?
  # service_account_scopes = var.service_account_scopes ?
  # network = "projects/${data.google_project.project.project_id}/global/networks/${local.network_name}"
  # subnet  = "projects/${data.google_project.project.project_id}/regions/${local.region}/subnetworks/${local.subnetwork}"
  network = data.google_compute_network.shared_vpc.self_link
  subnet  = data.google_compute_subnetwork.subnet.self_link
  # post_startup_script  = Assuming we don't need this
  # nic_type = ?
  # custom_gpu_driver_path ?
  # reservation_affinity {
  #   # (Required) The type of Compute Reservation. Possible values are: NO_RESERVATION, ANY_RESERVATION, SPECIFIC_RESERVATION
  #   consume_reservation_type = "NO_RESERVATION"
  #   # (Optional) Corresponds to the label key of reservation resource
  #   key =
  #   # (Optional) Corresponds to the label values of reservation resource.
  #   values =
  # }

  service_account = "project-service-account@${data.google_project.project.project_id}.iam.gserviceaccount.com"

  vm_image {
    project      = var.image_project
    image_family = var.image_family
    image_name   = var.image_name
  }

  dynamic "container_image" {
    for_each = var.container_repository != null ? [1] : []
    content {
      repository = var.container_repository
      tag        = var.container_tag
    }
  }

  install_gpu_driver = var.install_gpu_driver
  dynamic "accelerator_config" {
    for_each = var.install_gpu_driver == true ? [1] : []
    content {
      type       = var.accelerator_type
      core_count = var.core_count
    }
  }

  tags = var.tags

  boot_disk_type    = var.boot_disk_type
  boot_disk_size_gb = var.boot_disk_size_gb
  # data_disk_type = ?
  data_disk_size_gb = var.data_disk_size_gb
  # no_remove_data_disk = ?
  no_public_ip    = var.no_public_ip
  no_proxy_access = var.no_proxy_access
  labels = {
    environment  = data.google_project.project.labels.environment
    boundry_code = var.boundry_code
  }
  # tags = ?
  metadata = {
    notebook-disable-root     = "true"
    notebook-upgrade-schedule = "00 19 * * MON"
    terraform                 = "true"
  }
  # Do we want lifecycle here?
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      create_time,
      disk_encryption,
      # kms_key,
      update_time,
      vm_image,
    labels]
  }

  dynamic "shielded_instance_config" {
    for_each = var.install_gpu_driver == false ? [1] : []
    content {
      enable_integrity_monitoring = var.enable_integrity_monitoring
      enable_secure_boot          = var.enable_secure_boot
      enable_vtpm                 = var.enable_vtpm
    }
  }
}
