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

variable "env" {
  description = "The environment to prepare (ex. development)"
  type        = string
}

variable "environment_code" {
  type        = string
  description = "A short form of the folder level resources (environment) within the Google Cloud organization (ex. d)."
}

variable "remote_state_bucket" {
  description = "Backend bucket to load Terraform Remote State Data from previous steps."
  type        = string
}

variable "tfc_org_name" {
  description = "Name of the TFC organization"
  type        = string
}

variable "monitoring_workspace_users" {
  description = "Google Workspace or Cloud Identity group that have access to Monitoring Workspaces."
  type        = string
}

variable "project_budget" {
  description = <<EOT
  Budget configuration for projects.
  budget_amount: The amount to use as the budget.
  alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
  alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
  alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
  EOT
  type = object({
    base_network_budget_amount                  = optional(number, 1000)
    base_network_alert_spent_percents           = optional(list(number), [1.2])
    base_network_alert_pubsub_topic             = optional(string, null)
    base_network_budget_alert_spend_basis       = optional(string, "FORECASTED_SPEND")
    restricted_network_budget_amount            = optional(number, 1000)
    restricted_network_alert_spent_percents     = optional(list(number), [1.2])
    restricted_network_alert_pubsub_topic       = optional(string, null)
    restricted_network_budget_alert_spend_basis = optional(string, "FORECASTED_SPEND")
    monitoring_budget_amount                    = optional(number, 1000)
    monitoring_alert_spent_percents             = optional(list(number), [1.2])
    monitoring_alert_pubsub_topic               = optional(string, null)
    monitoring_budget_alert_spend_basis         = optional(string, "FORECASTED_SPEND")
    secret_budget_amount                        = optional(number, 1000)
    secret_alert_spent_percents                 = optional(list(number), [1.2])
    secret_alert_pubsub_topic                   = optional(string, null)
    secret_budget_alert_spend_basis             = optional(string, "FORECASTED_SPEND")
    kms_budget_amount                           = optional(number, 1000)
    kms_alert_spent_percents                    = optional(list(number), [1.2])
    kms_alert_pubsub_topic                      = optional(string, null)
    kms_budget_alert_spend_basis                = optional(string, "FORECASTED_SPEND")
    logging_budget_amount                       = optional(number, 1000)
    logging_alert_spent_percents                = optional(list(number), [1.2])
    logging_alert_pubsub_topic                  = optional(string, null)
    logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
  })
  default = {}
}

variable "assured_workload_configuration" {
  description = <<EOT
  Assured Workload configuration. See https://cloud.google.com/assured-workloads ."
  enabled: If the assured workload should be created.
  location: The location where the workload will be created.
  display_name: User-assigned resource display name.
  compliance_regime: Supported Compliance Regimes. See https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/ComplianceRegime .
  resource_type: The type of resource. One of CONSUMER_FOLDER, KEYRING, or ENCRYPTION_KEYS_PROJECT.
  EOT
  type = object({
    enabled           = optional(bool, false)
    location          = optional(string, "us-central1")
    display_name      = optional(string, "FEDRAMP-MODERATE")
    compliance_regime = optional(string, "FEDRAMP_MODERATE")
    resource_type     = optional(string, "CONSUMER_FOLDER")
  })
  default = {}
}

variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "sample-keyring"
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "gcs_bucket_prefix" {
  description = "Bucket Prefix"
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of environment logging bucket"
  type        = string
  default     = "us-central1"
}

variable "gcs_logging_retention_period" {
  description = "Retention configuration for environment logging bucket"
  type = object({
    is_locked             = bool
    retention_period_days = number
  })
  default = null
}

variable "gcs_logging_key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}

variable "kms_prevent_destroy" {
  description = "Wheter to prevent keyring and keys destruction. Must be set to false if the user wants to disable accidental terraform deletions protection."
  type        = bool
  default     = true
}
