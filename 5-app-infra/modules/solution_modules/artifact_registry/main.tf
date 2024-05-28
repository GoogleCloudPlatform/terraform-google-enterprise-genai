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

resource "google_artifact_registry_repository" "registry" {
  provider = google-beta

  project                = data.google_project.project.project_id
  location               = var.region
  repository_id          = var.name
  description            = var.description
  format                 = var.format
  cleanup_policy_dry_run = var.cleanup_policy_dry_run

  #Customer Managed Encryption Keys
  #Control ID: COM-CO-2.3
  #NIST 800-53: SC-12 SC-13
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1

  kms_key_name = data.google_kms_crypto_key.key.id

  #Cleanup policy
  #Control ID:  AR-CO-6.1
  #NIST 800-53: SI-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = condition.value[0].tag_state
          tag_prefixes          = condition.value[0].tag_prefixes
          package_name_prefixes = condition.value[0].package_name_prefixes
          older_than            = condition.value[0].older_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = most_recent_versions.value[0].package_name_prefixes
          keep_count            = most_recent_versions.value[0].keep_count
        }
      }
    }
  }
}
