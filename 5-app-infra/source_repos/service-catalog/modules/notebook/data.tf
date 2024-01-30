/**
 * Copyright 2023 Google LLC
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

data "google_project" "project" {
  project_id = var.project_id
}

data "google_projects" "kms" {
  filter = "labels.application_name:env-kms labels.environment:${data.google_project.project.labels.environment} lifecycleState:ACTIVE"
}

data "google_projects" "vpc" {
  filter = "labels.application_name:restricted-shared-vpc-host labels.environment:${data.google_project.project.labels.environment} lifecycleState:ACTIVE"
  # filter = "labels.application_name:base-shared-vpc-host labels.environment:${data.google_project.project.labels.environment} lifecycleState:ACTIVE"
}

data "google_compute_network" "shared_vpc" {
  name = "vpc-${data.google_project.project.labels.env_code}-shared-restricted"
  # name    = "vpc-${data.google_project.project.labels.env_code}-shared-base"
  project = data.google_projects.vpc.projects.0.project_id
}

data "google_compute_subnetwork" "subnet" {
  name = "sb-${data.google_project.project.labels.env_code}-shared-restricted-${local.region}"
  # name    = "sb-${data.google_project.project.labels.env_code}-shared-base-${local.region}"
  project = data.google_projects.vpc.projects.0.project_id
  region  = local.region
}

data "google_kms_key_ring" "kms" {
  name     = "sample-keyring"
  location = local.region
  project  = data.google_projects.kms.projects.0.project_id
}

data "google_kms_crypto_key" "key" {
  name     = data.google_project.project.name
  key_ring = data.google_kms_key_ring.kms.id
}

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
