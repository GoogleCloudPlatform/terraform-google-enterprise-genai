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

locals {
  current_user_email  = data.google_client_openid_userinfo.current_user.email
  current_user_domain = split("@", local.current_user_email)[1]
  current_member      = strcontains(local.current_user_domain, "iam.gserviceaccount.com") ? "serviceAccount:${local.current_user_email}" : "user:${local.current_user_email}"
  env_code            = substr(var.environment, 0, 1)
  name_var            = format("%s-%s", local.env_code, var.name)
  # key_ring_var = "projects/${var.cmek_project_id}/locations/${var.region}/keyRings/sample-keyring"
  region_short_code = {
    "us-central1" = "usc1"
    "us-east4"    = "use4"
  }
  # github_owner     = split("/", split("https://github.com/", var.github_remote_uri)[1])[0]
  # github_repo_name = trim(basename(var.github_remote_uri), ".git")

  trigger_sa_roles = [
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
  ]
  # github_repository = replace(var.github_remote_uri, "https://", "")
}
