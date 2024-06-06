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

output "private_endpoint_ip_address" {
  description = "The private IP address of the vector search endpoint"
  value       = google_compute_address.vector_search_static_ip.address
}

output "host_vpc_project_id" {
  description = "This is the Project ID where the Host VPC network is located"
  value       = var.vector_search_vpc_project
}

output "host_vpc_network" {
  description = "This is the Self-link of the Host VPC network"
  value       = var.network
}

output "notebook_project_id" {
  description = "The Project ID where the notebook will be run on"
  value       = var.machine_learning_project
}

output "vector_search_bucket_name" {
  description = "The name of the bucket that Vector Search will use"
  value       = google_storage_bucket.vector_search_bucket.name
}
