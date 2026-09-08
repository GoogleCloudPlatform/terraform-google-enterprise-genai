# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "project_id" {
  description = "GCP project ID hosting the _Default log bucket and the Cloud Monitoring dashboard."
  type        = string
}

variable "audit_log_services" {
  description = "List of services to enable Data Access audit logging (DATA_READ and DATA_WRITE) for authorization debugging."
  type        = list(string)
  default = [
    "iap.googleapis.com",
    "networkservices.googleapis.com",
    "networksecurity.googleapis.com",
  ]
}

variable "enable_logs_sink" {
  description = "Enable creation of log sink resources."
  type        = bool
  default     = false
}

variable "log_sink_name" {
  description = "Name of the log sink for exporting agent platform logs."
  type        = string
  default     = "agent-platform-log-sink"
}

variable "log_sink_destination" {
  description = "Destination URI for the primary log sink (e.g. 'storage.googleapis.com/<bucket>', 'bigquery.googleapis.com/projects/<project>/datasets/<dataset>', 'pubsub.googleapis.com/projects/<project>/topics/<topic>', or 'logging.googleapis.com/projects/<project>/locations/<location>/buckets/<bucket>'). If null, primary log sink creation is skipped."
  type        = string
  default     = null
}

variable "log_sink_filter" {
  description = "Filter for the primary log sink. If null, a default filter covering Agent Gateway, Reasoning Engine, Cloud Run MCPs and IAP audit logs will be used."
  type        = string
  default     = null
}

variable "log_sinks" {
  description = "Map of additional custom log sinks to create."
  type = map(object({
    destination = string
    filter      = string
    disabled    = optional(bool, false)
    exclusions = optional(list(object({
      name        = string
      description = optional(string)
      filter      = string
      disabled    = optional(bool, false)
    })), [])
  }))
  default = {}
}
