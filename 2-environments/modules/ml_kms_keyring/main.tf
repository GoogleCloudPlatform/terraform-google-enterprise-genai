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

module "kms_keyrings" {
  for_each = toset(var.keyring_regions)

  source  = "terraform-google-modules/kms/google"
  version = "~> 2.3"

  project_id      = var.project_id
  keyring         = var.keyring_name
  location        = each.key
  prevent_destroy = var.prevent_destroy
}

resource "google_project_iam_member" "kms_admins" {
  for_each = toset(var.keyring_admins)

  project = var.project_id
  role    = "roles/cloudkms.admin"
  member  = each.value
}
