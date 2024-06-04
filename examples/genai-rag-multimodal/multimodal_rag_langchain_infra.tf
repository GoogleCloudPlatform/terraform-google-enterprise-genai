

resource "google_workbench_instance" "instance" {
  disable_proxy_access = false
  instance_owners      = []
  location             = var.instance_location
  name                 = var.machine_name
  project              = var.machine_learning_project

  gce_setup {
    service_accounts {
      email = google_service_account.notebook_runner.email
    }
    disable_public_ip = true
    machine_type      = var.machine_type
    metadata = {
      "disable-mixer"              = "false"
      "notebook-disable-downloads" = "true"
      "notebook-disable-root"      = "true"
      "notebook-disable-terminal"  = "true"
      "notebook-upgrade-schedule"  = "00 19 * * MON"
      "report-dns-resolution"      = "true"
      "report-event-health"        = "true"
      "terraform"                  = "true"
    }
    tags = [
      "egress-internet",
    ]
    boot_disk {
      disk_encryption = "CMEK"
      disk_size_gb    = "150"
      disk_type       = "PD_SSD"
      kms_key         = var.kms_key
    }
    data_disks {
      disk_encryption = "CMEK"
      disk_size_gb    = "150"
      disk_type       = "PD_SSD"
      kms_key         = var.kms_key
    }
    network_interfaces {
      network = var.network
      subnet  = var.subnet
    }
    vm_image {
      family  = "workbench-instances"
      project = "cloud-notebooks-managed"
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_storage_bucket" "vector_search_bucket" {
  name                        = "vector-search-${random_string.suffix.result}"
  location                    = "US"
  project                     = var.machine_learning_project
  uniform_bucket_level_access = true
}

resource "google_compute_address" "vector_search_static_ip" {
  name         = var.vector_search_address_name
  region       = var.vector_search_ip_region
  subnetwork   = var.subnet
  project      = var.vector_search_vpc_project
  address_type = "INTERNAL"
}

resource "google_service_account" "notebook_runner" {
  account_id   = var.service_account_name
  display_name = "RAG Notebook Runner Service Account"
  project      = var.machine_learning_project
}

# IAM Roles

resource "google_project_iam_member" "notebook_runner_roles" {
  for_each = toset([
    "roles/aiplatform.user"
  ])
  project = var.machine_learning_project
  role    = each.key
  member  = google_service_account.notebook_runner.member
}

resource "google_storage_bucket_iam_member" "notebook_runner_bucket_admin" {
  bucket = google_storage_bucket.vector_search_bucket.name
  role   = "roles/storage.admin"
  member = google_service_account.notebook_runner.member
}
