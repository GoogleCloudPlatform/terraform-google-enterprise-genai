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
