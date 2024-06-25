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

resource "google_storage_bucket" "bucket" {
  provider = google-beta
  name     = join("-", [var.gcs_bucket_prefix, data.google_project.project.effective_labels.env_code, var.name])
  project  = var.project_id
  location = upper(var.region)

  dynamic "custom_placement_config" {
    for_each = length(var.dual_region_locations) != 0 ? [1] : []
    content {
      data_locations = var.dual_region_locations
    }
  }

  force_destroy               = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
  storage_class               = var.storage_class
  public_access_prevention    = "enforced"

  #Versioning is Enabled
  #Control ID: GCS-CO-6.2 and GCS-CO-6.7
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  versioning {
    enabled = var.versioning_enabled
  }

  #Labeling Tag
  #Control ID: GCS-CO-6.4
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  labels = var.labels

  #Retention Policy
  #Control ID: GCS-CO-6.17
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  dynamic "retention_policy" {
    for_each = var.retention_policy != {} ? [var.retention_policy] : []
    content {

      #Ensure Retention policy is using the bucket lock
      #Control ID: GCS-CO-6.13
      #NIST 800-53: SC-12
      #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

      is_locked        = lookup(retention_policy.value, "is_locked", null)
      retention_period = lookup(retention_policy.value, "retention_period", null)
    }
  }

  #Ensure Lifecycle management is enabled 1 of 2
  #Control ID: GCS-CO-6.13
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  #Ensure Lifecycle management is enabled 2 of 2
  #Control ID: GCS-CO-6.14
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type = lifecycle_rule.value.action.type

        #Regional Storage Class Lifecycle Rule
        #Control ID: GCS-CO-6.11
        #NIST 800-53: SC-12
        #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age            = lookup(lifecycle_rule.value.condition, "age", null)
        created_before = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state     = lookup(lifecycle_rule.value.condition, "with_state", lookup(lifecycle_rule.value.condition, "is_live", false) ? "LIVE" : null)

        #Regional Storage Class Lifecycle Rule
        #Control ID: GCS-CO-6.12
        #NIST 800-53: SC-12
        #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

        matches_storage_class      = contains(keys(lifecycle_rule.value.condition), "matches_storage_class") ? split(",", lifecycle_rule.value.condition["matches_storage_class"]) : null
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        custom_time_before         = lookup(lifecycle_rule.value.condition, "custom_time_before", null)
        days_since_custom_time     = lookup(lifecycle_rule.value.condition, "days_since_custom_time", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
        noncurrent_time_before     = lookup(lifecycle_rule.value.condition, "noncurrent_time_before", null)
      }
    }
  }

  #Customer Managed Encryption Keys
  #Control ID: COM-CO-2.3
  #NIST 800-53: SC-12 SC-13
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1

  encryption {
    default_kms_key_name = data.google_kms_crypto_key.key.id
  }

  #Log Bucket Exists
  #Control ID: GCS-CO-6.3 and GCS-CO-7.1
  #NIST 800-53: AU-2 AU-3 AU-8 AU-9
  #CRI Profile: DM.ED-7.1 DM.ED-7.2 DM.ED-7.3 DM.ED-7.4 PR.IP-1.4

  logging {
    log_bucket = var.log_bucket
  }
}

resource "google_storage_bucket_object" "root_folder" {
  name    = "root/"
  content = " "
  bucket  = google_storage_bucket.bucket.name

  #Object contains a temporary hold and should be evaluated
  #Control ID: GCS-CO-6.16
  #NIST 800-53: SC-12
  #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

  temporary_hold = var.object_folder_temporary_hold

  #Customer Managed Encryption Keys
  #Control ID: COM-CO-2.3
  #NIST 800-53: SC-12 SC-13
  #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1
}
