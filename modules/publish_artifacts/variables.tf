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

variable "region" {
  description = "Location of the repository."
  type        = string
}

variable "name" {
  description = "Name of the repository."
  type        = string
}

variable "description" {
  description = "Description of the repository."
  type        = string
}

variable "format" {
  description = "Format of the repository."
  type        = string
}

variable "cleanup_policy_dry_run" {
  description = "Whether to perform a dry run of the cleanup policy."
  type        = bool
  default     = false
}

variable "cleanup_policies" {
  description = "List of cleanup policies."
  type = list(object({
    id     = string
    action = optional(string)
    condition = optional(list(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
    })))
    most_recent_versions = optional(list(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    })))
  }))
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "project_name" {
  description = "Artifact Publish project name."
  type        = string
}

variable "project_number" {
  description = "Project number"
  type        = string
}

variable "kms_crypto_key" {
  description = "KMS Key to be used"
  type        = string
}

variable "docker_build_sa_id" {
  description = "Account Id of Docker Build Pipeline SA"
  type        = string
  default     = "docker-build"
}

variable "bucket_force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

variable "artifacts_infra_pipeline_sa" {
  description = "Full email of the terraform service account for artifact publish"
  type        = string
}

variable "cloud_source_artifacts_repo_name" {
  description = "Name to give the could source repository for Artifacts."
  type        = string
  default     = "publish-artifacts"
}

/******************************************
  KMS variables
*****************************************/
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

variable "key_rings" {
  description = "Keyrings to attach project key to."
  type        = map(string)
}

variable "keyring_regions" {
  type = list(string)
}
