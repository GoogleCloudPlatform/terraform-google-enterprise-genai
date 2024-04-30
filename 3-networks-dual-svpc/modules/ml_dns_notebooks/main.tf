data "google_netblock_ip_ranges" "private_apis" {
  range_type = "private-googleapis"
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cidr_block = data.google_netblock_ip_ranges.private_apis.cidr_blocks_ipv4[0]

  cidr_prefix = split("/", local.cidr_block)[1]

  # Calculate the number of available IP addresses
  ip_count = range(pow(2, 32 - local.cidr_prefix))

  # Generate a list of IP addresses
  google_private_ip_addresses = [for i in range(pow(2, 32 - local.cidr_prefix)) : cidrhost(local.cidr_block, i)]

  project_labels          = data.google_project.project.labels
  project_suffix_env_code = contains(keys(local.project_labels, "env_code")) ? local.project_labels.env_code : ""
}

/***********************************************
  Notebooks DNS Zone & records.
 ***********************************************/

module "notebooks" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${local.project_suffix_env_code}-shared-restricted-notebooks"
  domain      = "notebooks.cloud.google.com."
  description = "Private DNS zone to configure notebooks - cloud.google.com"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["notebooks.cloud.google.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.private_service_connect_ip]
    },
  ]
}

module "notebooks-googleusercontent" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${local.project_suffix_env_code}-shared-restricted-notebooks-googleusercontent"
  domain      = "notebooks.googleusercontent.com."
  description = "Private DNS zone to configure notebooks - googleusercontent.com"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["notebooks.googleusercontent.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [var.private_service_connect_ip]
    },
  ]
}

module "kernels-googleusercontent" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "~> 5.0"
  project_id  = var.project_id
  type        = "private"
  name        = "dz-${local.project_suffix_env_code}-shared-restricted-kernels-googleusercontent"
  domain      = "kernels.googleusercontent.com."
  description = "Private DNS zone to configure remote kernels for workbench"

  private_visibility_config_networks = [
    module.main.network_self_link
  ]

  recordsets = [
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["kernels.googleusercontent.com."]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.google_private_ip_addresses
    },
  ]
}