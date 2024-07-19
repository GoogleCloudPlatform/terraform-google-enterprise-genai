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

variable "name" {
  type        = string
  description = "Name of the notebook instance."
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
  type        = string
  description = "Type of the machine to spin up for the notebook."
  default     = "e2-standard-4"
}

variable "instance_owners" {
  type        = set(string)
  description = "Email of the owner of the instance, e.g. alias@example.com. Only one owner is supported!"
}


variable "accelerator_type" {
  type        = string
  description = "The type of accelerator to use."
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
  description = "Number of accelerators to use."
  default     = 1
}

variable "image_project" {
  type        = string
  description = "The name of the Google Cloud project that this VM image belongs to. Format: projects/{project_id}."
  default     = "cloud-notebooks-managed"
}

variable "image_family" {
  type        = string
  description = "Use this VM image family to find the image; the newest image in this family will be used."
  default     = "workbench-instances"
}

variable "image_name" {
  type        = string
  description = "Use VM image name to find the image."
  default     = ""
}

variable "install_gpu_driver" {
  type        = bool
  description = "Whether the end user authorizes Google Cloud to install GPU driver on this instance. Only applicable to instances with GPUs."
  default     = false
}

variable "boot_disk_type" {
  type        = string
  description = "Possible disk types for notebook instances."
  default     = "PD_SSD"
  validation {
    condition     = contains(["DISK_TYPE_UNSPECIFIED", "PD_STANDARD", "PD_SSD", "PD_BALANCED", "PD_EXTREME"], var.boot_disk_type)
    error_message = "Illegal value for boot disk type"
  }
}

variable "boot_disk_size_gb" {
  type        = string
  description = "(Optional) The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB)."
  default     = "150"
}

variable "data_disk_type" {
  type        = string
  description = "(Optional) Input only. Indicates the type of the disk. Possible values are: PD_STANDARD, PD_SSD, PD_BALANCED, PD_EXTREME."
  default     = "PD_SSD"
  validation {
    condition     = contains(["PD_STANDARD", "PD_SSD", "PD_BALANCED", "PD_EXTREME"], var.data_disk_type)
    error_message = "Illegal value for data disk type"
  }
}

variable "data_disk_size_gb" {
  type        = string
  description = "(Optional) The size of the data disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB)"
  default     = "150"
}


variable "disable_proxy_access" {
  type        = bool
  description = "(Optional) The notebook instance will not register with the proxy"
  default     = false
}

variable "boundry_code" {
  type        = string
  description = "The boundry code for the tenant"
  default     = "001"
}

variable "project_id" {
  type        = string
  description = "Project ID to deploy the instance."
}

variable "tags" {
  type        = list(string)
  description = "The Compute Engine tags to add to instance."
  default     = ["egress-internet"]
}

variable "kms_keyring" {
  type        = string
  description = <<EOF
    The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as var.location and the same environment.
    This value can be obtained by running "gcloud kms keyrings list --project=KMS_PROJECT_ID --location=REGION".
  EOF
}

variable "vpc_project" {
  type        = string
  description = <<EOF
  This is the project id of the Restricted Shared VPC Host Project for your environment.
  This value can be obtained by running "gcloud projects list --filter='labels.application_name:restricted-shared-vpc-host lifecycleState:ACTIVE'" and selecting the project.
  EOF
}

variable "kms_key_name" {
  type        = string
  description = <<EOF
The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step"
EOF
  default     = ""
}
