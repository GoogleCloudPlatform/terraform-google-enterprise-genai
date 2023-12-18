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
  env_code = substr(var.environment, 0, 1)
  name_var = format("%s-%s", local.env_code, var.name)

  github_owner     = split("/", split("https://github.com/", var.github_remote_uri)[1])[0]
  github_repo_name = trim(basename(var.github_remote_uri), ".git")

  trigger_sa_roles = [
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
  ]
}
