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
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "The numeric identifier (e.g., 123456789012) of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "GCP region for Model Armor template"
  type        = string
}

variable "enable_model_armor" {
  description = "Enable Model Armor template and IAM bindings"
  type        = bool
  default     = true
}

variable "enable_iam_bindings" {
  description = "Enable IAM role bindings for Model Armor service account"
  type        = bool
  default     = true
}

variable "enable_mcp_floor_setting" {
  description = "Enable Model Armor floor setting for MCP server protection"
  type        = bool
  default     = true
}

variable "request_template_id" {
  description = "ID for the request-side Model Armor template"
  type        = string
  default     = "agw-request-template"
}

variable "response_template_id" {
  description = "ID for the response-side Model Armor template"
  type        = string
  default     = "agw-response-template"
}

# RAI Filter Configuration
variable "rai_filters" {
  description = "RAI (Responsible AI) filter configurations. filter_type can be: SEXUALLY_EXPLICIT, HATE_SPEECH, HARASSMENT, DANGEROUS. confidence_level can be: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH"
  type = list(object({
    filter_type      = string
    confidence_level = string
  }))
  default = [
    {
      filter_type      = "HATE_SPEECH"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "HARASSMENT"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "SEXUALLY_EXPLICIT"
      confidence_level = "MEDIUM_AND_ABOVE"
    }
  ]
  validation {
    condition = alltrue([
      for filter in var.rai_filters :
      contains(["SEXUALLY_EXPLICIT", "HATE_SPEECH", "HARASSMENT", "DANGEROUS"], filter.filter_type)
    ])
    error_message = "filter_type must be one of: SEXUALLY_EXPLICIT, HATE_SPEECH, HARASSMENT, DANGEROUS"
  }
  validation {
    condition = alltrue([
      for filter in var.rai_filters :
      contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], filter.confidence_level)
    ])
    error_message = "confidence_level must be one of: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH"
  }
}

variable "sdp_enforcement" {
  description = "Sensitive Data Protection filter enforcement (ENABLED builds DLP inspect/de-identify templates and wires them into the response template's sdp_settings.advanced_config; DISABLED creates no DLP/SDP resources)"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.sdp_enforcement)
    error_message = "sdp_enforcement must be ENABLED or DISABLED"
  }
}

variable "pii_types" {
  description = "PII info types fed into the DLP inspect template's info_types (only consulted when sdp_enforcement = ENABLED). Common types include: US_SOCIAL_SECURITY_NUMBER, CREDIT_CARD_NUMBER, PHONE_NUMBER, EMAIL_ADDRESS, PASSPORT, DATE_OF_BIRTH, MEDICAL_RECORD_NUMBER, IP_ADDRESS, STREET_ADDRESS, PERSON_NAME, etc."
  type        = list(string)
  default = [
    "US_SOCIAL_SECURITY_NUMBER",
    "CREDIT_CARD_NUMBER",
    "PHONE_NUMBER",
    "EMAIL_ADDRESS",
    "PASSPORT",
    "DATE_OF_BIRTH",
    "MEDICAL_RECORD_NUMBER"
  ]
}

variable "inspect_template_id" {
  description = "ID for the DLP inspect template wired into the response Model Armor template's sdp_settings.advanced_config (only created when sdp_enforcement = ENABLED)"
  type        = string
  default     = "agw-ssn-inspect-template"
}

variable "deidentify_template_id" {
  description = "ID for the DLP de-identify template wired into the response Model Armor template's sdp_settings.advanced_config (only created when sdp_enforcement = ENABLED)"
  type        = string
  default     = "agw-ssn-redaction-template"
}

# PI and Jailbreak Filter Settings
variable "pi_jailbreak_enforcement" {
  description = "PI and jailbreak filter enforcement setting (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.pi_jailbreak_enforcement)
    error_message = "pi_jailbreak_enforcement must be ENABLED or DISABLED"
  }
}

variable "pi_jailbreak_confidence_level" {
  description = "PI and jailbreak filter confidence level (LOW_AND_ABOVE, MEDIUM_AND_ABOVE, or HIGH)"
  type        = string
  default     = "LOW_AND_ABOVE"
  validation {
    condition     = contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], var.pi_jailbreak_confidence_level)
    error_message = "pi_jailbreak_confidence_level must be one of: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH"
  }
}

# Malicious URI Filter Settings
variable "malicious_uri_enforcement" {
  description = "Malicious URI filter enforcement setting (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.malicious_uri_enforcement)
    error_message = "malicious_uri_enforcement must be ENABLED or DISABLED"
  }
}

# Error Messages and Codes
variable "llm_response_error_code" {
  description = "Custom error code for LLM response safety evaluation failures"
  type        = number
  default     = 798
}

variable "llm_response_error_message" {
  description = "Custom error message for LLM response safety evaluation failures"
  type        = string
  default     = "LLM response blocked by content filter"
}

variable "prompt_error_code" {
  description = "Custom error code for prompt safety evaluation failures"
  type        = number
  default     = 799
}

variable "prompt_error_message" {
  description = "Custom error message for prompt safety evaluation failures"
  type        = string
  default     = "Your request was blocked by our content filter. Please rephrase your prompt and try again."
}

variable "ignore_partial_failures" {
  description = "Whether to ignore partial invocation failures"
  type        = bool
  default     = true
}

variable "log_template_operations" {
  description = "Whether to log template CRUD operations"
  type        = bool
  default     = true
}

variable "log_sanitize_operations" {
  description = "Whether to log sanitize operations"
  type        = bool
  default     = true
}

variable "platform_admin_members" {
  description = "List of IAM members to grant modelarmor.admin and modelarmor.floorSettingsAdmin roles (e.g. [\"user:admin@example.com\"])"
  type        = list(string)
  default     = []
}

# ==============================================================================
# VERTEX AI INTEGRATION
# ==============================================================================

variable "enable_vertex_ai_integration" {
  description = "Enable Model Armor integration with Vertex AI (floor setting + IAM for AI Platform service agent)"
  type        = bool
  default     = false
}

variable "vertex_ai_inspect_only" {
  description = "When true, Vertex AI uses INSPECT_ONLY mode; when false, uses INSPECT_AND_BLOCK"
  type        = bool
  default     = false
}

variable "vertex_ai_enable_cloud_logging" {
  description = "Enable Cloud Logging for Vertex AI Model Armor sanitization"
  type        = bool
  default     = true
}
