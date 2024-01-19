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

data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

// Cloud IAP's TCP forwarding netblock
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_projects" "kms" {
  filter = "labels.application_name:env-kms labels.environment:${data.google_project.project.labels.environment} lifecycleState:ACTIVE"
}

data "google_kms_key_ring" "kms" {
  name     = local.keyring_name
  location = var.region
  project  = data.google_projects.kms.projects.0.project_id
}

data "google_kms_crypto_key" "key" {
  name     = data.google_project.project.name
  key_ring = data.google_kms_key_ring.kms.id
}

data "google_service_account" "composer" {
  account_id = format("%s-%s-%s", var.service_account_prefix, data.google_project.project.labels.env_code, "composer")
  project    = data.google_project.project.project_id
}
