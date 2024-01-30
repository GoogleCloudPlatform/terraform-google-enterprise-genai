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

output "id" {
  description = "an identifier for the resource with format projects/{{project}}/locations/{{location}}/instances/{{name}}"
  value = google_workbench_instance.instance.id
}

output "proxy_uri" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = google_workbench_instance.instance.proxy_uri
}

output "state" {
  description = "The state of this instance."
  value       = google_workbench_instance.instance.state
}

output "create_time" {
  description = "Instance creation time"
  value       = google_workbench_instance.instance.create_time
}

output "update_time" {
  description = "Instance update time."
  value = google_workbench_instance.instance.update_time
}

output "terraform_labels" {
  description = "The combination of labels configured directly on the resource and default labels configured on the provider."
  value       = google_workbench_instance.instance.terraform_labels
}

output "effective_labels" {
  description = "All of labels (key/value pairs) present on the resource in GCP, including the labels configured through Terraform, other clients and services."
  value       = google_workbench_instance.instance.effective_labels
}
