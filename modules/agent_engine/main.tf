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

# =============================================================================
# Agent Identity IAM bindings
# Grants permissions to all Agent Engine agents in this project.
# See: https://docs.cloud.google.com/agent-builder/agent-engine/agent-identity
# =============================================================================
locals {
  agent_identity_principal = "principalSet://agents.global.org-${var.org_id}.system.id.goog/attribute.platformContainer/aiplatform/projects/${var.project_number}"
}

resource "google_project_iam_member" "agent_identity_service_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_browser" {
  project = var.project_id
  role    = "roles/browser"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_express_user" {
  project = var.project_id
  role    = "roles/aiplatform.expressUser"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_api_registry_viewer" {
  project = var.project_id
  role    = "roles/cloudapiregistry.viewer"
  member  = local.agent_identity_principal
}

# Required for the agent to call agentregistry.googleapis.com mcpServers.list
# during startup discovery. Without this, list_mcp_servers() returns 403.
resource "google_project_iam_member" "agent_identity_agent_registry_viewer" {
  project = var.project_id
  role    = "roles/agentregistry.viewer"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = local.agent_identity_principal
}

resource "google_project_iam_member" "agent_identity_telemetry_writer" {
  project = var.project_id
  role    = "roles/telemetry.writer"
  member  = local.agent_identity_principal
}

# =============================================================================
# Agent MCP invoker service account
# Agents impersonate this SA at runtime to mint OIDC ID tokens for invoking
# MCP Cloud Run services. The SA itself is granted
# `roles/run.invoker` on each MCP service in modules/mcp-cloud-run, so Cloud
# Run sees the impersonated SA as the caller (the agent identity is not
# propagated; Cloud Run does not accept agents.global principalSet members
# directly today, May 2026).
# =============================================================================

resource "google_service_account" "agent_mcp_invoker" {
  project      = var.project_id
  account_id   = "agent-mcp-invoker"
  display_name = "Agent MCP invoker SA"
  description  = "OIDC token target for agents calling MCP Cloud Run services. Agent identity has project-level Token Creator allowing impersonation of this and other project SAs."
}

resource "google_service_account_iam_member" "agent_identity_token_creator" {
  role               = "roles/iam.serviceAccountTokenCreator"
  service_account_id = google_service_account.agent_mcp_invoker.name
  member             = local.agent_identity_principal
}

# =============================================================================
# User IAM bindings
# =============================================================================

resource "google_project_iam_member" "aiplatform_admin" {
  for_each = toset(var.platform_admin_members)

  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = each.value
}
