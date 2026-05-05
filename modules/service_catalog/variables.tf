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

/******************************************
  Project
*****************************************/
variable "name" {
  description = "Name of the repository."
  type        = string
}

variable "project_name" {
  description = "Service Catalog project name"
  type        = string
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "project_number" {
  description = "Project number"
  type        = string
}

variable "region" {
  description = "Location of the repository."
  type        = string
}

/******************************************
  Service Account
*****************************************/
variable "service_catalog_pipeline_sa" {
  description = "Full email of the terraform service account for service-catalog"
  type        = string
}

variable "trigger_sa_id" {
  description = "Account Id of Docker Build Pipeline SA"
  type        = string
  default     = "svc-catalog"
}

/******************************************
  Storage
*****************************************/
variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for GCS Bucket."
  default     = "bkt"
}

variable "log_bucket" {
  description = "Bucket to store logs from service catalog bucket"
  type        = string
}

variable "bucket_force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

/******************************************
  Machine Learning project
*****************************************/
variable "machine_learning_project_number" {
  description = "Machine Learning (Vertex) project number"
  type        = string
}

/******************************************
  KMS
*****************************************/
variable "kms_crypto_key" {
  description = "KMS Key to be used"
  type        = string
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
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

variable "key_rings" {
  description = "Keyrings to attach project key to."
  type        = map(string)
}
