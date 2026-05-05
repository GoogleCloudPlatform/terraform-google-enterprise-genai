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

variable "folder_id" {
  description = "The folder to deploy in."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID associated with the projects, e.g. XXXXXX-YYYYYY-ZZZZZZ."
  type        = string
}

variable "labels" {
  description = "(Optional) Labels attached to Machine Learning resources."
  type        = map(string)
  default     = {}
}

variable "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code."
  type        = string
}

variable "instance_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "bucket_force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets that contain objects."
  type        = bool
  default     = false
}

/******************************************
  Projects variables
*****************************************/
variable "seed_project_id" {
  description = "Seed project ID."
  type        = string
  default     = ""
}

variable "seed_project_name" {
  description = "Seed project name."
  type        = string
  default     = ""
}

variable "kms_project_id" {
  description = "KMS project ID."
  type        = string
}

variable "kms_project_number" {
  description = "KMS project number."
  type        = string
}

variable "logging_project_id" {
  description = "Logging project ID."
  type        = string
}

variable "logging_project_name" {
  description = "Logging project name."
  type        = string
}

variable "logging_project_number" {
  description = "Logging project number."
  type        = string
}

variable "machine_learning_project_id" {
  description = "Machine Learning project ID."
  type        = string
}

variable "machine_learning_project_number" {
  description = "Machine Learning project number."
  type        = string
}

variable "machine_learning_project_name" {
  description = "Machine Learning project name."
  type        = string
}

variable "artifact_publish_project_id" {
  description = "Artifact publishing project ID for Machine Learning projects."
  type        = string
}

variable "artifact_publish_project_number" {
  description = "Artifact publishing project number for Machine Learning projects."
  type        = string
}

variable "artifact_publish_project_name" {
  description = "Artifact publishing project name."
  type        = string
}

variable "service_catalog_project_id" {
  description = "Service Catalog project ID."
  type        = string
}

variable "service_catalog_project_number" {
  description = "Service Catalog project number."
  type        = string
}

variable "service_catalog_project_name" {
  description = "Service Catalog project name."
  type        = string
}

variable "projects_deletion_policy" {
  description = "Project deletion policy. Possible values are: \"PREVENT\", \"ABANDON\", \"DELETE\"."
  type        = string
  default     = "PREVENT"
}

/******************************************
  KMS Key Ring variables
*****************************************/

variable "keyring_name" {
  description = "Name to be used for the KMS key ring."
  type        = string
  default     = "sample-keyring"
}

variable "keys" {
  description = "Key names."
  type        = list(string)
  default     = []
}

variable "keyring_regions" {
  description = "Regions to create key rings in."
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "keyring_admins" {
  description = "IAM members that shall be granted admin on the key ring. Format must specify member type, i.e. 'serviceAccount:', 'user:', 'group:'."
  type        = list(string)
}

variable "key_rotation_period" {
  description = "Rotation period in seconds to be used for the KMS key."
  type        = string
  default     = "7776000s"
}

variable "kms_prevent_destroy" {
  description = "If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present."
  type        = bool
  default     = true
}

/******************************************
  DNS for notebook LM variables
*****************************************/

variable "restricted_network_self_link" {
  description = "The URI of the Machine Learning VPC being created."
  type        = list(string)
  default     = []
}

variable "private_service_connect_ip" {
  type        = string
  description = "Internal IP to be used as the Private Service Connect endpoint."
  default     = "10.10.64.5"
}

variable "private_visibility_config_networks" {
  description = "List of VPC self links that can see this zone."
  type        = list(string)
}

/*****************************************
  Service Controls variables
*****************************************/

variable "access_context_manager_policy_id" {
  description = "The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format=\"value(name)\"`."
  type        = number
}

variable "access_level_name" {
  description = "The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format=\"value(name)\"`."
  type        = string
  default     = ""
}

variable "access_level_name_dry_run" {
  description = "The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format=\"value(name)\"`."
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
  description = "List of services to restrict in an enforced perimeter."
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


variable "machine_learning_perimeter" {
  description = "Existing Machine Learning perimeter to be used instead of the auto-created perimeter. The service account provided in the variable `terraform_service_account` must be in an access level member list for this perimeter **before** this perimeter can be used in this module."
  type        = string
  default     = ""
}

variable "egress_policies" {
  description = "A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference) to use in an enforced perimeter. Each list object has a `from` and `to` value that describes egress_from and egress_to.\n\nExample: `[{ from={ identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)."
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "egress_policies_dry_run" {
  description = "A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes egress_from and egress_to.\n\nExample: `[{ from={ identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)."
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies" {
  description = "A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in an enforced perimeter. Each list object has a `from` and `to` value that describes ingress_from and ingress_to.\n\nExample: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)."
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies_dry_run" {
  description = "A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes ingress_from and ingress_to.\n\nExample: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type=\"ID_TYPE\" }, to={ resources=[], operations={ \"SRV_NAME\"={ OP_TYPE=[] }}}}]`\n\nValid values:\n`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`\n`SRV_NAME` = \"`*`\" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)\n`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions)."
  type = list(object({
    from = any
    to   = any
  }))
  default = []
}

variable "ingress_policies_keys" {
  description = "A list of keys to use for the Terraform state. The order should correspond to var.ingress_policies and the keys must not be dynamically computed. If `null`, var.ingress_policies will be used as keys."
  type        = list(string)
  default     = []
}

variable "egress_policies_keys" {
  description = "A list of keys to use for the Terraform state. The order should correspond to var.egress_policies and the keys must not be dynamically computed. If `null`, var.egress_policies will be used as keys."
  type        = list(string)
  default     = []
}

variable "ingress_policies_keys_dry_run" {
  description = "(Dry-run) A list of keys to use for the Terraform state. The order should correspond to var.ingress_policies_dry_run and the keys must not be dynamically computed. If `null`, var.ingress_policies_dry_run will be used as keys."
  type        = list(string)
  default     = []
}

variable "egress_policies_keys_dry_run" {
  description = "(Dry-run) A list of keys to use for the Terraform state. The order should correspond to var.egress_policies_dry_run and the keys must not be dynamically computed. If `null`, var.egress_policies_dry_run will be used as keys."
  type        = list(string)
  default     = []
}

variable "vpc_sc_propagation_sleep_duration" {
  description = "The duration to wait for VPC Service Controls propagation (e.g., 60s, 2m)."
  type        = string
  default     = "60s"
}

/******************************************
  Artifact Publishing variables
*****************************************/

variable "cloud_source_artifacts_repo_name" {
  description = "Name to give the Cloud Source repository for artifacts."
  type        = string
  default     = "publish-artifacts"
}

/******************************************
  Service Catalog variables
*****************************************/

variable "cloud_source_service_catalog_repo_name" {
  description = "Name to give the Cloud Source repository for Service Catalog."
  type        = string
  default     = "service-catalog"
}

/*****************************************
  Firewall variables
*****************************************/

variable "allow_all_egress_ranges" {
  description = "List of network ranges to which all egress traffic will be allowed."
  default     = null
}

variable "allow_all_ingress_ranges" {
  description = "List of network ranges from which all ingress traffic will be allowed."
  default     = null
}

variable "firewall_enable_logging" {
  type        = bool
  description = "Toggle firewall logging for VPC firewalls."
  default     = true
}

variable "network_name" {
  type        = string
  description = "Network name."
}

/*****************************************
  Bucket variables
*****************************************/

variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for GCS Bucket."
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of the environment logging bucket."
  type        = string
  default     = "us-central1"
}

variable "gcs_logging_retention_period" {
  description = "Retention configuration for the environment logging bucket."
  type = object({
    is_locked             = bool
    retention_period_days = number
  })
  default = null
}
