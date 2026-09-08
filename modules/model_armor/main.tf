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

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  service_extensions_sa_email = "service-${data.google_project.project.number}@gcp-sa-dep.iam.gserviceaccount.com"
  enable_sdp_advanced         = var.enable_model_armor && var.sdp_enforcement == "ENABLED"
}

resource "google_project_service" "dlp" {
  count              = local.enable_sdp_advanced ? 1 : 0
  project            = var.project_id
  service            = "dlp.googleapis.com"
  disable_on_destroy = false
}

resource "google_data_loss_prevention_inspect_template" "ssn" {
  count        = local.enable_sdp_advanced ? 1 : 0
  parent       = "projects/${var.project_id}/locations/${var.region}"
  template_id  = var.inspect_template_id
  display_name = "SSN Inspect Template"

  inspect_config {
    dynamic "info_types" {
      for_each = var.pii_types
      content {
        name = info_types.value
      }
    }
    min_likelihood = "POSSIBLE"
  }

  depends_on = [google_project_service.dlp]
}

resource "google_data_loss_prevention_deidentify_template" "ssn" {
  count        = local.enable_sdp_advanced ? 1 : 0
  parent       = "projects/${var.project_id}/locations/${var.region}"
  template_id  = var.deidentify_template_id
  display_name = "SSN Redaction Template"

  deidentify_config {
    info_type_transformations {
      transformations {
        # Scope the replace transformation to ONLY the info types the operator
        # asked for in var.pii_types. Without this filter, the transformation
        # applies to every finding — and Model Armor's SDP filter detects
        # PERSON_NAME on its own (alongside the custom inspect template),
        # which then gets replaced with [PERSON_NAME] even though PERSON_NAME
        # is not in var.pii_types. Listing the info types here makes findings
        # of any other type pass through untransformed.
        dynamic "info_types" {
          for_each = var.pii_types
          content {
            name = info_types.value
          }
        }
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }
    }
  }
}

resource "google_project_service_identity" "model_armor" {
  count    = local.enable_sdp_advanced ? 1 : 0
  provider = google-beta
  project  = var.project_id
  service  = "modelarmor.googleapis.com"
}

resource "google_project_iam_member" "model_armor_dlp_user" {
  count   = local.enable_sdp_advanced ? 1 : 0
  project = var.project_id
  role    = "roles/dlp.user"
  member  = "serviceAccount:${google_project_service_identity.model_armor[0].email}"
}

resource "google_project_iam_member" "model_armor_dlp_reader" {
  count   = local.enable_sdp_advanced ? 1 : 0
  project = var.project_id
  role    = "roles/dlp.reader"
  member  = "serviceAccount:${google_project_service_identity.model_armor[0].email}"
}

resource "google_project_iam_member" "service_extensions_container_admin" {
  count   = var.enable_model_armor && var.enable_iam_bindings ? 1 : 0
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "service_extensions_callout_user" {
  count   = var.enable_model_armor && var.enable_iam_bindings ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.calloutUser"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "service_extensions_service_usage" {
  count   = var.enable_model_armor && var.enable_iam_bindings ? 1 : 0
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "service_extensions_model_armor_user" {
  count   = var.enable_model_armor && var.enable_iam_bindings ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.user"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "model_armor_admin" {
  count   = var.enable_model_armor ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.admin"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "model_armor_floor_settings_admin" {
  count   = var.enable_model_armor ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.floorSettingsAdmin"
  member  = "serviceAccount:${local.service_extensions_sa_email}"
}

resource "google_project_iam_member" "vertex_ai_model_armor_user" {
  count   = var.enable_model_armor && var.enable_vertex_ai_integration ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.user"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

module "request_template" {
  count   = var.enable_model_armor ? 1 : 0
  source  = "GoogleCloudPlatform/vertex-ai/google//modules/model-armor-template"
  version = "~> 7.3"

  project_id  = var.project_id
  location    = var.region
  template_id = var.request_template_id

  rai_filters = {
    for f in var.rai_filters : lower(f.filter_type) => f.confidence_level
  }

  pi_and_jailbreak_filter_settings = var.pi_jailbreak_enforcement == "ENABLED" ? var.pi_jailbreak_confidence_level : null

  enable_malicious_uri_filter_settings = var.malicious_uri_enforcement == "ENABLED"

  metadata_configs = {
    custom_llm_response_safety_error_code    = var.llm_response_error_code
    custom_llm_response_safety_error_message = var.llm_response_error_message
    custom_prompt_safety_error_code          = var.prompt_error_code
    custom_prompt_safety_error_message       = var.prompt_error_message
    ignore_partial_invocation_failures       = var.ignore_partial_failures
    log_template_operations                  = var.log_template_operations
    log_sanitize_operations                  = var.log_sanitize_operations
  }

  depends_on = [google_project_iam_member.model_armor_admin]
}

module "response_template" {
  count   = var.enable_model_armor ? 1 : 0
  source  = "GoogleCloudPlatform/vertex-ai/google//modules/model-armor-template"
  version = "~> 7.3"

  project_id  = var.project_id
  location    = var.region
  template_id = var.response_template_id

  rai_filters = {
    for f in var.rai_filters : lower(f.filter_type) => f.confidence_level
  }

  sdp_settings = local.enable_sdp_advanced ? {
    advanced_config = {
      inspect_template    = google_data_loss_prevention_inspect_template.ssn[0].id
      deidentify_template = google_data_loss_prevention_deidentify_template.ssn[0].id
    }
  } : null

  pi_and_jailbreak_filter_settings = var.pi_jailbreak_enforcement == "ENABLED" ? var.pi_jailbreak_confidence_level : null

  enable_malicious_uri_filter_settings = var.malicious_uri_enforcement == "ENABLED"

  metadata_configs = {
    custom_llm_response_safety_error_code    = var.llm_response_error_code
    custom_llm_response_safety_error_message = var.llm_response_error_message
    custom_prompt_safety_error_code          = var.prompt_error_code
    custom_prompt_safety_error_message       = var.prompt_error_message
    ignore_partial_invocation_failures       = var.ignore_partial_failures
    log_template_operations                  = var.log_template_operations
    log_sanitize_operations                  = var.log_sanitize_operations
  }

  depends_on = [
    google_project_iam_member.model_armor_admin,
    google_data_loss_prevention_inspect_template.ssn,
    google_data_loss_prevention_deidentify_template.ssn,
    google_project_iam_member.model_armor_dlp_user,
    google_project_iam_member.model_armor_dlp_reader,
  ]
}

module "mcp_floor_setting" {
  count   = var.enable_model_armor && (var.enable_mcp_floor_setting || var.enable_vertex_ai_integration) ? 1 : 0
  source  = "GoogleCloudPlatform/vertex-ai/google//modules/model-armor-floorsetting"
  version = "~> 7.3"

  project_id = var.project_id

  enable_floor_setting_enforcement = true

  integrated_services = compact(concat(
    var.enable_vertex_ai_integration ? ["AI_PLATFORM"] : [],
    var.enable_mcp_floor_setting ? ["GOOGLE_MCP_SERVER"] : [],
  ))

  rai_filters = {
    for f in var.rai_filters : lower(f.filter_type) => f.confidence_level
  }

  pi_and_jailbreak_filter_settings = var.pi_jailbreak_enforcement == "ENABLED" ? var.pi_jailbreak_confidence_level : null

  enable_malicious_uri_filter_settings = true

  ai_platform_floor_setting = var.enable_vertex_ai_integration ? {
    inspect_only         = var.vertex_ai_inspect_only
    inspect_and_block    = !var.vertex_ai_inspect_only
    enable_cloud_logging = var.vertex_ai_enable_cloud_logging
  } : null

  google_mcp_server_floor_setting = var.enable_mcp_floor_setting ? {
    inspect_and_block    = true
    enable_cloud_logging = var.vertex_ai_enable_cloud_logging
  } : null

  depends_on = [
    google_project_iam_member.model_armor_admin,
    google_project_iam_member.model_armor_floor_settings_admin,
  ]
}

resource "null_resource" "mcp_content_security" {
  count = var.enable_model_armor && var.enable_mcp_floor_setting ? 1 : 0

  provisioner "local-exec" {
    command = "gcloud beta services mcp content-security add modelarmor.googleapis.com --project=${var.project_id}"
  }

  depends_on = [module.mcp_floor_setting]
}
