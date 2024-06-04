variable "service_account_name" {
  description = "The name of the service account"
  type        = string
  default     = "rag-notebook-runner"
}

variable "machine_learning_project" {
  description = "Machine Learning Project ID"
  type        = string
}

variable "vector_search_address_name" {
  description = "The name of the address to create"
  type        = string
  default     = "vector-search-endpoint"
}

variable "vector_search_ip_region" {
  description = "The region to create the address in"
  type        = string
  default     = "us-central1"
}

variable "vector_search_vpc_project" {
  description = "The project ID where the Host VPC network is located"
  type        = string
}

variable "kms_key" {
  description = "The KMS key to use for disk encryption"
  type        = string
}

variable "network" {
  description = "The Host VPC network ID to connect the instance to"
  type        = string
}

variable "subnet" {
  description = "The subnet ID within the Host VPC network to use in Vertex Workbench and Private Service Connect"
  type        = string
}

variable "machine_type" {
  description = "The type of machine to use for the instance"
  type        = string
  default     = "e2-standard-2"
}

variable "machine_name" {
  description = "The name of the machine instance"
  type        = string
  default     = "rag-notebook-instance"
}

variable "instance_location" {
  description = "Vertex Workbench Instance Location"
  type        = string
  default     = "us-central1-a"
}
