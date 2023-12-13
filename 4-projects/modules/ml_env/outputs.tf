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

output "machine_learning_project" {
  description = "Project machine learning project."
  value       = module.machine_learning_project.project_id
}

output "machine_learning_project_number" {
  description = "Project number of machine learning project."
  value       = module.machine_learning_project.project_number
}

output "machine_learning_key_id" {
  description = "Key ID for the machine learning project."
  value       = values(google_kms_crypto_key.ml_key)[*].id
}
