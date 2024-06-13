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
  description = "The Organization ID."
  type        = string
}

variable "folder_id" {
  description = "The folder id where project will be created."
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associated this project with."
  type        = string
}

variable "project_suffix" {
  description = "The name of the GCP project. Max 16 characters with 3 character business unit code."
  type        = string
}

variable "application_name" {
  description = "The name of application where GCP resources relate."
  type        = string
}

variable "billing_code" {
  description = "The code that's used to provide chargeback information."
  type        = string
}

variable "primary_contact" {
  description = "The primary email contact for the project."
  type        = string
}

variable "secondary_contact" {
  description = "The secondary email contact for the project."
  type        = string
  default     = ""
}

variable "business_code" {
  description = "The code that describes which business unit owns the project."
  type        = string
  default     = "abcd"
}

variable "activate_apis" {
  description = "The api to activate for the GCP project."
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "The environment the project belongs to."
  type        = string
}

variable "vpc_type" {
  description = "The type of VPC to attach the project to. Possible options are `base` or `restricted`."
  type        = string
  default     = ""
}

variable "shared_vpc_host_project_id" {
  description = "Shared VPC host project ID."
  type        = string
  default     = ""
}

variable "shared_vpc_subnets" {
  description = "List of the shared vpc subnets self links."
  type        = list(string)
  default     = []
}

variable "vpc_service_control_attach_enabled" {
  description = "Whether the project will be attached to a VPC Service Control Perimeter."
  type        = bool
  default     = false
}

variable "vpc_service_control_perimeter_name" {
  description = "The name of a VPC Service Control Perimeter to add the created project to."
  type        = string
  default     = null
}

variable "vpc_service_control_sleep_duration" {
  description = "The duration to sleep in seconds before adding the project to a shared VPC after the project is added to the VPC Service Control Perimeter."
  type        = string
  default     = "5s"
}

variable "project_budget" {
  description = <<EOT
  Budget configuration.
  budget_amount: The amount to use as the budget.
  alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
  alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
  alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
  EOT
  type = object({
    budget_amount        = optional(number, 1000)
    alert_spent_percents = optional(list(number), [1.2])
    alert_pubsub_topic   = optional(string, null)
    alert_spend_basis    = optional(string, "FORECASTED_SPEND")
  })
  default = {}
}

variable "project_prefix" {
  description = "Name prefix to use for projects created."
  type        = string
  default     = "prj"
}

variable "app_infra_pipeline_service_accounts" {
  description = "The Service Accounts from App Infra Pipeline."
  type        = map(string)
  default     = {}
}

variable "sa_roles" {
  description = "A list of roles to give the Service Account from App Infra Pipeline."
  type        = map(list(string))
  default     = {}
}

variable "enable_cloudbuild_deploy" {
  description = "Enable infra deployment using Cloud Build."
  type        = bool
  default     = false
}

variable "key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key."
  type        = string
  default     = "7776000s"
}

variable "key_rings" {
  description = "Keyrings to attach project key to."
  type        = list(string)
}

variable "remote_state_bucket" {
  description = "Backend bucket to load Terraform Remote State Data from previous steps."
  type        = string
}

variable "default_service_account" {
  description = "Project default service account setting: can be one of `delete`, `depriviledge`, `keep` or `disable`."
  type        = string
  default     = "disable"
}

variable "environment_kms_project_id" {
  description = "Environment level KMS Project ID."
  type        = string
}

variable "project_name" {
  description = "Project Name."
  type        = string
}

variable "prevent_destroy" {
  description = "Prevent Key destruction."
  type        = bool
}