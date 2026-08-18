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

variable "machine_learning_project_id" {
  description = "Machine Learning Project ID"
  type        = string
}

variable "machine_learning_project_number" {
  description = "Machine Learning Project Number"
  type        = string
}

variable "region" {
  type        = string
  description = "The resource region, one of [us-central1, us-east4]."
  default     = "us-central1"
  validation {
    condition     = contains(["us-central1", "us-east4"], var.region)
    error_message = "Region must be one of [us-central1, us-east4]."
  }
}

variable "kms_project_id" {
  description = "KMS Project Number"
  type        = string
}

variable "service_catalog_project_id" {
  description = "Service Catalog Project ID"
  type        = string
}

variable "cloud_source_artifacts_repo_name" {
  description = "Name to give the could source repository for Artifacts"
  type        = string
  default     = "publish-artifacts"
}

variable "artifact_publish_project_id" {
  description = "Publish Artifacts Project ID for ML Projects"
  type        = string
}

variable "machine_learning_project_name" {
  description = "Machine Learning Project Name"
  type        = string
}

variable "kms_prevent_destroy" {
  description = "If set to true, delete KMS keyring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present."
  type        = bool
  default     = true
}

variable "key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}

variable "kms_crypto_key" {
  description = "KMS Key to be used"
  type        = string
}

variable "key_rings" {
  description = "Keyrings to attach project key to."
  type        = map(string)
}

variable "keyring_regions" {
  type = list(string)
}

variable "machine_learning_pipeline_sa" {
  description = "The email address of the service account that will run the Terraform code."
  type        = string
}
