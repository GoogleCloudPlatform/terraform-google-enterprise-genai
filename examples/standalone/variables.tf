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

variable "project_prefix" {
  description = "Name prefix to use for projects created. Should be the same in all steps. Max size is 3 characters."
  type        = string
  default     = "prj"
}

variable "storage_bucket_labels" {
  description = "Labels to apply to the storage bucket."
  type        = map(string)
  default     = {}
}

variable "encrypt_gcs_bucket_tfstate" {
  description = "Encrypt the bucket used for storing Terraform state files in the seed project."
  type        = bool
  default     = true
}

variable "nat_bgp_asn" {
  type        = number
  description = "BGP ASN for NAT cloud route. This is needed to allow the Jenkins Agent to download packages and updates from the internet without having an external IP address."
  default     = 64512
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
  description = "The list of additional members to be added to the enforced perimeter access level members list. Prefix user: (user:email@email.com) or serviceAccount: (serviceAccount:my-service-account@email.com) is required."
  type        = list(string)
  default     = []
}

variable "perimeter_additional_members_dry_run" {
  description = "The list of additional members to be added to the dry-run perimeter access level members list. To be able to see the resources protected by the VPC Service Controls in the restricted perimeter, add your user in this list. Entries must be in the standard GCP form: `user:email@example.com` or `serviceAccount:my-service-account@example.com`."
  type        = list(string)
  default     = []
}

variable "egress_policies" {
  description = "A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference), each list object has a `from` and `to` value that describes egress_from and egress_to.\n\nExample: `[{ from={ identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid Values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)"
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "egress_policies_dry_run" {
  description = "A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference), each list object has a `from` and `to` value that describes egress_from and egress_to.\n\nExample: `[{ from={ identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid Values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)"
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies" {
  description = "A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference), each list object has a `from` and `to` value that describes ingress_from and ingress_to.\n\nExample: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid Values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)"
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies_dry_run" {
  description = "A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes ingress_from and ingress_to.\n\nExample: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid Values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)"
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
