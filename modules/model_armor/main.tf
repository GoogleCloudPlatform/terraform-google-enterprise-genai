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

resource "google_model_armor_template" "request" {
  count       = var.enable_model_armor ? 1 : 0
  project     = var.project_id
  location    = var.region
  template_id = var.request_template_id

  depends_on = [google_project_iam_member.model_armor_admin]

  filter_config {
    rai_settings {
      dynamic "rai_filters" {
        for_each = var.rai_filters
        content {
          filter_type      = rai_filters.value.filter_type
          confidence_level = rai_filters.value.confidence_level
        }
      }
    }

    pi_and_jailbreak_filter_settings {
      filter_enforcement = var.pi_jailbreak_enforcement
      confidence_level   = var.pi_jailbreak_confidence_level
    }

    malicious_uri_filter_settings {
      filter_enforcement = var.malicious_uri_enforcement
    }
  }

  template_metadata {
    custom_llm_response_safety_error_code    = var.llm_response_error_code
    custom_llm_response_safety_error_message = var.llm_response_error_message
    custom_prompt_safety_error_code          = var.prompt_error_code
    custom_prompt_safety_error_message       = var.prompt_error_message
    ignore_partial_invocation_failures       = var.ignore_partial_failures
    log_template_operations                  = var.log_template_operations
    log_sanitize_operations                  = var.log_sanitize_operations
  }
}

resource "google_model_armor_template" "response" {
  count       = var.enable_model_armor ? 1 : 0
  project     = var.project_id
  location    = var.region
  template_id = var.response_template_id

  depends_on = [
    google_project_iam_member.model_armor_admin,
    google_data_loss_prevention_inspect_template.ssn,
    google_data_loss_prevention_deidentify_template.ssn,
    google_project_iam_member.model_armor_dlp_user,
    google_project_iam_member.model_armor_dlp_reader,
  ]

  filter_config {
    rai_settings {
      dynamic "rai_filters" {
        for_each = var.rai_filters
        content {
          filter_type      = rai_filters.value.filter_type
          confidence_level = rai_filters.value.confidence_level
        }
      }
    }

    dynamic "sdp_settings" {
      for_each = local.enable_sdp_advanced ? [1] : []
      content {
        advanced_config {
          inspect_template    = google_data_loss_prevention_inspect_template.ssn[0].id
          deidentify_template = google_data_loss_prevention_deidentify_template.ssn[0].id
        }
      }
    }

    pi_and_jailbreak_filter_settings {
      filter_enforcement = var.pi_jailbreak_enforcement
      confidence_level   = var.pi_jailbreak_confidence_level
    }

    malicious_uri_filter_settings {
      filter_enforcement = var.malicious_uri_enforcement
    }
  }

  template_metadata {
    custom_llm_response_safety_error_code    = var.llm_response_error_code
    custom_llm_response_safety_error_message = var.llm_response_error_message
    custom_prompt_safety_error_code          = var.prompt_error_code
    custom_prompt_safety_error_message       = var.prompt_error_message
    ignore_partial_invocation_failures       = var.ignore_partial_failures
    log_template_operations                  = var.log_template_operations
    log_sanitize_operations                  = var.log_sanitize_operations
  }
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
  for_each = var.enable_model_armor ? toset(var.platform_admin_members) : toset([])
  project  = var.project_id
  role     = "roles/modelarmor.admin"
  member   = each.value
}

resource "google_project_iam_member" "model_armor_floor_settings_admin" {
  for_each = var.enable_model_armor ? toset(var.platform_admin_members) : toset([])
  project  = var.project_id
  role     = "roles/modelarmor.floorSettingsAdmin"
  member   = each.value
}

resource "google_model_armor_floorsetting" "mcp_floor_setting" {
  count    = var.enable_model_armor && (var.enable_mcp_floor_setting || var.enable_vertex_ai_integration) ? 1 : 0
  parent   = "projects/${var.project_id}"
  location = "global"

  depends_on = [
    google_project_iam_member.model_armor_admin,
    google_project_iam_member.model_armor_floor_settings_admin,
  ]

  enable_floor_setting_enforcement = true

  integrated_services = compact(concat(
    var.enable_vertex_ai_integration ? ["AI_PLATFORM"] : [],
    var.enable_mcp_floor_setting ? ["GOOGLE_MCP_SERVER"] : [],
  ))

  filter_config {
    rai_settings {
      dynamic "rai_filters" {
        for_each = var.rai_filters
        content {
          filter_type      = rai_filters.value.filter_type
          confidence_level = rai_filters.value.confidence_level
        }
      }
    }
    pi_and_jailbreak_filter_settings {
      filter_enforcement = var.pi_jailbreak_enforcement
      confidence_level   = var.pi_jailbreak_confidence_level
    }
    malicious_uri_filter_settings {
      filter_enforcement = var.malicious_uri_enforcement
    }
  }

  dynamic "ai_platform_floor_setting" {
    for_each = var.enable_vertex_ai_integration && var.vertex_ai_inspect_only ? [1] : []
    content {
      inspect_only         = true
      enable_cloud_logging = var.vertex_ai_enable_cloud_logging
    }
  }

  dynamic "ai_platform_floor_setting" {
    for_each = var.enable_vertex_ai_integration && !var.vertex_ai_inspect_only ? [1] : []
    content {
      inspect_and_block    = true
      enable_cloud_logging = var.vertex_ai_enable_cloud_logging
    }
  }

  dynamic "google_mcp_server_floor_setting" {
    for_each = var.enable_mcp_floor_setting ? [1] : []
    content {
      inspect_and_block    = true
      enable_cloud_logging = var.vertex_ai_enable_cloud_logging
    }
  }
}

# Enable Model Armor content security scanning on the MCP server
# No Terraform resource exists for this, so we use a null_resource with local-exec
resource "null_resource" "mcp_content_security" {
  count = var.enable_model_armor && var.enable_mcp_floor_setting ? 1 : 0

  provisioner "local-exec" {
    command = "gcloud beta services mcp content-security add modelarmor.googleapis.com --project=${var.project_id}"
  }

  depends_on = [google_model_armor_floorsetting.mcp_floor_setting]
}

resource "google_project_iam_member" "vertex_ai_model_armor_user" {
  count   = var.enable_model_armor && var.enable_vertex_ai_integration ? 1 : 0
  project = var.project_id
  role    = "roles/modelarmor.user"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}
