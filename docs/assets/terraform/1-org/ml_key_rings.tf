module "kms_keyring" {
  source = "../../modules/ml_kms_keyring"

  keyring_admins = [
    "serviceAccount:${local.projects_step_terraform_service_account_email}"
  ]
  project_id      = module.org_kms.project_id
  keyring_regions = var.keyring_regions
  keyring_name    = var.keyring_name
}
