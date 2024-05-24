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

locals {
  ephemeral_keys_for_each = var.prevent_destroy ? [] : var.key_rings
  keys_for_each           = var.prevent_destroy ? var.key_rings : []
  output_keys             = var.prevent_destroy ? { for k, v in google_kms_crypto_key.kms_keys : split("/", k)[3] => v } : { for k, v in google_kms_crypto_key.ephemeral_kms_keys : split("/", k)[3] => v }
}

resource "google_kms_crypto_key" "ephemeral_kms_keys" {
  for_each = toset(local.ephemeral_keys_for_each)

  name            = var.project_name
  key_ring        = each.key
  rotation_period = var.key_rotation_period
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "kms_keys" {
  for_each = toset(local.keys_for_each)

  name            = var.project_name
  key_ring        = each.key
  rotation_period = var.key_rotation_period
  lifecycle {
    prevent_destroy = true
  }
}
