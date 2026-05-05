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
  description = "The numeric organization ID."
  type        = string
}

variable "parent_folder" {
  description = "The folder to deploy in."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID associated with the projects, e.g. XXXXXX-YYYYYY-ZZZZZZ."
  type        = string
}

variable "project_deletion_policy" {
  description = "The deletion policy for the project created."
  type        = string
  default     = "PREVENT"
}

/******************************************
  Projects
*****************************************/
variable "seed_project_name" {
  description = "Custom project name for the seed project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.seed_project_name) < 26
    error_message = "The seed_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

variable "kms_project_name" {
  description = "Custom project name for the KMS project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.kms_project_name) < 26
    error_message = "The kms_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

variable "logging_project_name" {
  description = "Custom project name for the logging project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.logging_project_name) < 26
    error_message = "The logging_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

variable "machine_learning_project_name" {
  description = "Custom project name for the Machine Learning project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.machine_learning_project_name) < 26
    error_message = "The machine_learning_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

variable "service_catalog_project_name" {
  description = "Custom project name for the Service Catalog project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.service_catalog_project_name) < 26
    error_message = "The service_catalog_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

variable "artifact_publish_project_name" {
  description = "Custom project name for the artifact publishing project."
  type        = string
  default     = ""

  validation {
    condition     = length(var.artifact_publish_project_name) < 26
    error_message = "The artifact_publish_project_name must contain fewer than 26 characters. This ensures the name can be suffixed with 4 random characters to create the project ID."
  }
}

/******************************************
  KMS
*****************************************/
variable "keyring_name" {
  description = "Name to be used for the KMS key ring."
  type        = string
  default     = "sample-keyring"
}

variable "keyring_regions" {
  description = "Regions to create key rings in."
  type        = list(string)
  default     = ["us-central1", "us-east4"]
}

variable "kms_prevent_destroy" {
  description = "If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present."
  type        = bool
  default     = true
}

/******************************************
  Storage
*****************************************/
variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for the GCS bucket."
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of the environment logging bucket."
  type        = string
  default     = "us-central1"
}

variable "bucket_force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets that contain objects."
  type        = bool
  default     = false
}

/******************************************
  Service accounts
*****************************************/
variable "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code."
  type        = string
}

/******************************************
  Network
*****************************************/

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

/******************************************
  DNS
*****************************************/
variable "private_service_connect_ip" {
  description = "Internal IP to be used as the Private Service Connect endpoint."
  type        = string
  default     = "10.10.64.5"
}

variable "restricted_network_self_link" {
  description = "The URI of the Machine Learning VPC being created."
  type        = list(string)
  default     = []
}

/******************************************
  Service Controls
*****************************************/
variable "access_context_manager_policy_id" {
  description = "The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --filter=\"title='Organization access level policy'\" --format=\"value(name)\"`."
  type        = number
}

variable "access_level_name" {
  description = "Access Context Manager access level name for the enforced perimeter."
  type        = string
  default     = ""
}

variable "access_level_name_dry_run" {
  description = "Access Context Manager access level name for the dry-run perimeter."
  type        = string
  default     = ""
}

variable "enforce_vpcsc" {
  description = "Enable the enforced mode for VPC Service Controls. It is not recommended to enable VPC-SC on the first run deploying your foundation. Review [best practices for enabling VPC Service Controls](https://cloud.google.com/vpc-service-controls/docs/enable), then only enforce the perimeter after you have analyzed the access patterns in your dry-run perimeter and created the necessary exceptions for your use cases."
  type        = bool
  default     = false
}

variable "custom_restricted_services" {
  type        = list(string)
  description = "List of services to restrict in an enforced perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected."
  default     = []
}

variable "custom_restricted_services_dry_run" {
  description = "List of custom services to be protected by the dry-run VPC-SC perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected."
  type        = list(string)
  default     = []
}

variable "perimeter_additional_members" {
  description = "The list of additional members to be added to perimeter access. Prefix user: (user:email@email.com) or serviceAccount: (serviceAccount:my-service-account@email.com) is required."
  type        = list(string)
  default     = []
}

variable "egress_policies" {
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "egress_policies_dry_run" {
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies" {
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies_dry_run" {
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "vpc_sc_propagation_sleep_duration" {
  description = "The duration to wait for VPC Service Controls propagation (e.g., 60s, 2m)."
  type        = string
  default     = "60s"
}

/******************************************
  Artifact Publishing
*****************************************/
variable "cloud_source_artifacts_repo_name" {
  description = "Name to give the Cloud Source repository for artifacts."
  type        = string
}

/******************************************
  Service Catalog
*****************************************/
variable "cloud_source_service_catalog_repo_name" {
  description = "Name to give the Cloud Source repository for Service Catalog."
  type        = string
}
