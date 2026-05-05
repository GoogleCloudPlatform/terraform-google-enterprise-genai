/**
 * Copyright 2026 Google LLC
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
  description = "The organization ID for the associated services."
  type        = string
}

variable "folder_id" {
  description = "The folder ID where the project will be created."
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with."
  type        = string
}

variable "activate_apis" {
  description = "The APIs to activate for the Google Cloud project."
  type        = list(string)
  default     = []
}

variable "project_deletion_policy" {
  description = "Project deletion policy. Possible values are: \"PREVENT\", \"ABANDON\", \"DELETE\"."
  type        = string
  default     = "PREVENT"
}

variable "seed_project_name" {
  description = "Custom project name for the seed project."
  type        = string
  default     = ""
}

variable "kms_project_name" {
  description = "Custom project name for the KMS project."
  type        = string
  default     = ""
}

variable "logging_project_name" {
  description = "Custom project name for the logging project."
  type        = string
  default     = ""
}

variable "machine_learning_project_name" {
  description = "Custom project name for the Machine Learning project."
  type        = string
  default     = ""
}

variable "service_catalog_project_name" {
  description = "Custom project name for the Service Catalog project."
  type        = string
  default     = ""
}

variable "artifact_publish_project_name" {
  description = "Custom project name for the artifact publishing project."
  type        = string
  default     = ""
}

variable "project_prefix" {
  description = "Name prefix to use for projects created. Should be the same in all steps. Max size is 3 characters."
  type        = string
  default     = "prj"
}

variable "kms_prevent_destroy" {
  description = "If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present."
  type        = bool
  default     = true
}

/******************************************
  Network variables
*****************************************/
variable "default_region" {
  description = "The region in which the subnetwork will be created."
  type        = string
}

/******************************************
  Seed project
*****************************************/

variable "storage_bucket_labels" {
  description = "Labels to apply to the storage bucket."
  type        = map(string)
  default     = {}
}

variable "bucket_force_destroy" {
  description = "If supplied, the state bucket will be deleted even while containing objects."
  type        = bool
  default     = false
}

variable "encrypt_gcs_bucket_tfstate" {
  description = "Encrypt the bucket used for storing Terraform state files in the seed project."
  type        = bool
  default     = true
}

variable "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code."
  type        = string
}
