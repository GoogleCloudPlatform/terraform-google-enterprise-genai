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

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "folder_id" {
  description = "Optional - Setting the folder_id will place all the organization policies on the provided folder instead of the root organization. The value is the numeric folder ID. The folder must already exist."
  type        = string
  default     = ""
}

variable "allowed_vertex_images" {
  description = <<EOT
  Restrict environment options on new Vertex AI Workbench notebooks and instances Organization Policy.
  This list defines the VM and container image options that can be select when creating new Vertex AI Workbench notebooks and instances.
  Format for VM instances is "ainotebooks-vm/PROJECT_ID/IMAGE_TYPE/CONSTRAINED_VALUE". Replace IMAGE_TYPE with image-family or image-name.
EOT
  type        = list(string)
  default = [
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cpu-notebooks",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py37",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu110.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-cpu.2-12.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-gpu.2-12.py310"
  ]
}

variable "allowed_vertex_vpc_networks" {
  description = <<EOT
  Restrict VPC networks on new Vertex AI Workbench instances Organization Policy.
  This list defines the projects id that contains the VPC networks a user can select when creating new Vertex AI Workbench instances.
  - parent_type: one of organization, folder, or project.
  - parent_id: list of ID of the parent type.
EOT
  type = object({
    parent_type = string
    parent_ids  = list(string)
  })

  validation {
    condition     = contains(["project", "folder", "organization"], var.allowed_vertex_vpc_networks.parent_type)
    error_message = "The allowed_vertex_vpc_networks.parent_type value must be one of: organization, folder, or project."
  }
}

variable "allowed_locations" {
  description = <<EOT
  Google Cloud Platform - Resource Location Restriction Organization Policy.
  Defines the set of locations where location-based Google Cloud resources can be created.
  EOT
  type        = list(string)
  default     = ["us-locations"]
}

variable "restricted_services" {
  description = <<EOT
  Restrict Resource Service Usage Organization Policy.
  Defines the set of Google Cloud resource services that cannot be used within an organization or folder.
  EOT
  type        = list(string)
  default     = ["alloydb.googleapis.com"]
}

variable "allowed_integrations" {
  description = <<EOT
  Allowed Integrations (Cloud Build) Organization Policy.
  Defines the allowed Cloud Build integrations for performing Builds through receiving webhooks from services outside Google Cloud.
  EOT
  type        = list(string)
  default     = ["github.com", "source.developers.google.com"]
}

variable "restricted_tls_versions" {
  description = <<EOT
  Restrict TLS Versions Organization Policy.
  Defines the set of TLS versions that cannot be used on the organization, folder, or project
  where this constraint is enforced, or any of that resource's children in the resource hierarchy.
  EOT
  type        = list(string)
  default     = ["TLS_VERSION_1", "TLS_VERSION_1_1"]
}

variable "restricted_non_cmek_services" {
  description = <<EOT
  Restrict which services may create resources without CMEK Organization Policy.
  Defines which services require Customer-Managed Encryption Keys (CMEK).
  Requires that, for the specified services, newly created resources must be protected by a CMEK key.
  EOT
  type        = list(string)
  default     = ["bigquery.googleapis.com", "aiplatform.googleapis.com"]
}

variable "allowed_vertex_access_modes" {
  description = <<EOT
  Define access mode for Vertex AI Workbench notebooks and instances Organization Policy.
  Defines the modes of access allowed to Vertex AI Workbench notebooks and instances.
  EOT
  type        = list(string)
  default     = ["single-user", "service-account"]
}
