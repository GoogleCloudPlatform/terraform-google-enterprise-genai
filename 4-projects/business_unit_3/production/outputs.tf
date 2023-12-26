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

output "composer_project_id" {
  description = "Project ID of composer project"
  value       = try(module.composer_cloudbuild_project[0].project_id, "")
}

output "composer_project_number" {
  description = "Project number of composer project"
  value       = try(module.composer_cloudbuild_project[0].project_number, "")
}

output "composer_project_name" {
  description = "Project name of composer project"
  value       = try(module.composer_cloudbuild_project[0].project_name, "")
}

output "composer_project_sa" {
  description = "SA of the composer project"
  value       = try(module.composer_cloudbuild_project[0].project_sa, "")
}

# output "composer_terraform_service_accounts" {
#   description = "Composer Terraform SA mapped to source repos as keys"
#   value       = try(module.composer_cloudbuild_project.terraform_service_accounts, {})
# }

# output "composer_repos" {
#   description = "CSR's to store source code for composer repo"
#   value       = try(module.composer_cloudbuild_project.repos, toset([]))
# }

# output "composer_artifact_buckets" {
#   description = "GCS Buckets to store Cloud Build Artifacts"
#   value       = try(module.composer_cloudbuild_project.artifact_buckets, {})
# }

# output "composer_state_buckets" {
#   description = "GCS Buckets to store TF state"
#   value       = try(module.composer_cloudbuild_project.state_buckets, {})
# }

# output "composer_log_buckets" {
#   description = "GCS Buckets to store Cloud Build logs"
#   value       = try(module.composer_cloudbuild_project.log_buckets, {})
# }

# output "composer_plan_triggers_id" {
#   description = "CB plan triggers"
#   value       = try(module.composer_cloudbuild_project.plan_triggers_id, [])
# }

# output "composer_apply_triggers_id" {
#   description = "CB apply triggers"
#   value       = try(module.composer_cloudbuild_project.apply_triggers_id, [])
# }

output "enable_cloudbuild_deploy" {
  description = "Enable infra deployment using Cloud Build."
  value       = local.enable_cloudbuild_deploy
}
