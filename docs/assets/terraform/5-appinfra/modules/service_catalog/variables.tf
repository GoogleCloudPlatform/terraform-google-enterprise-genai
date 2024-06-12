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

variable "name" {
  description = "Name of the repository."
  type        = string
}
variable "region" {
  description = "Location of the repository."
  type        = string
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "gcs_bucket_prefix" {
  description = "Prefix of the bucket name"
  default     = "bkt"
}

variable "tf_service_catalog_sa_email" {
  description = "Full email of the terraform service account for service-catalog"
  type        = string
}

variable "machine_learning_project_number" {
  description = "Project Number for the Machine Learning (Vertex) Project"
  type        = string
}

variable "kms_crypto_key" {
  description = "KMS Key to be used"
  type        = string
}

variable "log_bucket" {
  description = "Bucket to store logs from service catalog bucket"
  type        = string
}
