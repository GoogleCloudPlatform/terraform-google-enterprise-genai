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

resource "google_logging_project_bucket_config" "default_analytics" {
  project          = var.project_id
  location         = "global"
  bucket_id        = "_Default"
  enable_analytics = true
}

# The dashboard JSON ships with the `PROJECT_ID` placeholder in BigQuery-
# style table refs (`<project>.global._Default._AllLogs`); rewrite it to the
# caller's project.
resource "google_monitoring_dashboard" "authorization_debugging" {
  project = var.project_id
  dashboard_json = replace(
    file("${path.module}/authorization-debugging.json"),
    "PROJECT_ID",
    var.project_id,
  )

  lifecycle {
    ignore_changes = [dashboard_json]
  }
  depends_on = [google_logging_project_bucket_config.default_analytics]
}

# Enable Data Access audit logs (DATA_READ and DATA_WRITE) required for
# the authorization debugging dashboard via the official IAM audit_config module.
module "audit_config" {
  source  = "terraform-google-modules/iam/google//modules/audit_config"
  version = "~> 8.2"

  project = var.project_id

  audit_log_config = flatten([
    for svc in var.audit_log_services : [
      {
        service          = svc
        log_type         = "DATA_READ"
        exempted_members = []
      },
      {
        service          = svc
        log_type         = "DATA_WRITE"
        exempted_members = []
      }
    ]
  ])
}

locals {
  default_log_filter = <<-EOT
    resource.type = ("networkservices.googleapis.com/Gateway" OR "aiplatform.googleapis.com/ReasoningEngine" OR "cloud_run_revision") OR
    proto_payload.audit_log.service_name = ("iap.googleapis.com" OR "agentregistry.googleapis.com" OR "networksecurity.googleapis.com")
  EOT
}

# Primary log sink for agent platform logs via the official log-export module
module "log_export" {
  count   = var.enable_logs_sink && var.log_sink_destination != null ? 1 : 0
  source  = "terraform-google-modules/log-export/google"
  version = "~> 11.0"

  parent_resource_type   = "project"
  parent_resource_id     = var.project_id
  log_sink_name          = var.log_sink_name
  destination_uri        = var.log_sink_destination
  filter                 = var.log_sink_filter != null ? var.log_sink_filter : local.default_log_filter
  unique_writer_identity = true
}

# Optional additional custom log sinks via the official log-export module
module "custom_log_exports" {
  for_each = var.enable_logs_sink ? var.log_sinks : {}
  source   = "terraform-google-modules/log-export/google"
  version  = "~> 11.0"

  parent_resource_type   = "project"
  parent_resource_id     = var.project_id
  log_sink_name          = each.key
  destination_uri        = each.value.destination
  filter                 = each.value.filter
  disabled               = each.value.disabled
  exclusions             = each.value.exclusions
  unique_writer_identity = true
}
