/**
 * Copyright 2021 Google LLC
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
  # github_repository = replace(var.github_remote_uri, "https://", "")
  log_bucket_prefix = "bkt"
  bucket_permissions = {

    "roles/storage.admin" = [
      "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
    ],
    "roles/storage.legacyObjectReader" = [
      "serviceAccount:${var.machine_learning_project_number}@cloudbuild.gserviceaccount.com",
    ],
  }

  bucket_roles = flatten([
    for role in keys(local.bucket_permissions) : [
      for sa in local.bucket_permissions[role] :
      {
        role = role
        acct = sa
      }
    ]
  ])
}


