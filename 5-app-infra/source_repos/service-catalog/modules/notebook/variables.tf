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

variable "name" {
  description = "name of the notebook instance"
  type        = string
}

variable "location" {
  type        = string
  description = "Notebook instance location (zone)."
  default     = "us-central1-a"
  validation {
    condition     = contains(["us-central1", "us-east4"], substr(var.location, 0, length(var.location) - 2))
    error_message = "Location must be one within of [us-central1, us-east4] regions."
  }
}

variable "machine_type" {
  description = "type of the machine to spin up for the notebook"
  type        = string
  default     = "e2-standard-4"
}

variable "instance_owners" {
  description = "email of the owner of the instance, e.g. alias@example.com. Only one owner is supported!"
  type        = set(string)
}

# variable "service_account" {
#   description = "service account to attach to this instance"
#   type        = string
# }

# variable "service_account_scopes" {
#   description = <<EOT
#                 the uri of the service account scopes to be be included in Compute Engine instances.
#                 If not specified, the following scopes are defined: https://www.googleapis.com/auth/cloud-platform\
#                 https://www.googleapis.com/auth/userinfo.email
#                 EOT
#   type         = set(string)
# }

variable "accelerator_type" {
  description = "The type of accelerator to use"
  type        = string
  default     = "NVIDIA_TESLA_K80"
  validation {
    condition = contains(["ACCELERATOR_TYPE_UNSPECIFIED", "NVIDIA_TESLA_K80",
      "NVIDIA_TESLA_P100", "NVIDIA_TESLA_V100", "NVIDIA_TESLA_P4",
      "NVIDIA_TESLA_T4", "NVIDIA_TESLA_T4_VWS", "NVIDIA_TESLA_P100_VWS",
    "NVIDIA_TESLA_P4_VWS", "NVIDIA_TESLA_A100", "TPU_V2", "TPU_V3"], var.accelerator_type)
    error_message = "Accelerator type can be one of the following: "
  }
}
variable "core_count" {
  type        = number
  default     = 1
  description = "number of accelerators to use"
}

variable "image_project" {
  description = "The name of the Google Cloud project that this VM image belongs to. Format: projects/{project_id}"
  type        = string
  default     = "deeplearning-platform-release"
}

variable "image_family" {
  description = "Use this VM image family to find the image; the newest image in this family will be used."
  type        = string
  default     = null
}

variable "image_name" {
  description = "Use VM image name to find the image."
  type        = string
  default     = ""
}

variable "container_repository" {
  description = "The path to the container image repository. For example: gcr.io/{project_id}/{imageName}"
  type        = string
  default     = null
}

variable "container_tag" {
  description = "The tag of the container image. If not specified, this defaults to the latest tag."
  type        = string
  default     = "latest"
}

variable "install_gpu_driver" {
  description = "Whether the end user authorizes Google Cloud to install GPU driver on this instance. Only applicable to instances with GPUs."
  type        = bool
  default     = false
}

variable "boot_disk_type" {
  description = "Possible disk types for notebook instances"
  type        = string
  default     = "PD_SSD"
  validation {
    condition     = contains(["DISK_TYPE_UNSPECIFIED", "PD_STANDARD", "PD_SSD", "PD_BALANCED", "PD_EXTREME"], var.boot_disk_type)
    error_message = "Illegal value for disk type"
  }
}

variable "boot_disk_size_gb" {
  description = "(Optional) The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB)"
  type        = string
  default     = "100"
}

variable "data_disk_size_gb" {
  description = "(Optional) The size of the data disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB)"
  type        = string
  default     = "100"
}

variable "no_public_ip" {
  description = "No public IP will be assigned to this instance"
  type        = bool
  default     = true
}

variable "no_proxy_access" {
  description = "(Optional) The notebook instance will not register with the proxy"
  type        = bool
  default     = false
}

variable "boundry_code" {
  description = "The boundry code for the tenant"
  type        = string
  default     = "001"
}

variable "enable_integrity_monitoring" {
  description = "(Optional) Defines whether the instance has integrity monitoring enabled. Enables monitoring and attestation of the boot integrity of the instance"
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "(Optional) Defines whether the instance has Secure Boot enabled."
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "(Optional) Defines whether the instance has the vTPM enabled."
  type        = bool
  default     = true
}

variable "project_id" {
  type        = string
  description = "Optional Project ID."
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "The Compute Engine tags to add to instance."
  default     = ["egress-internet"]
}
