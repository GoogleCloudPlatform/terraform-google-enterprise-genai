<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| env | The environment this deployment belongs to (ie. development) | `string` | n/a | yes |
| instance\_region | Region which the peered subnet will be created (Should be same region as the VM that will be created on step 5-app-infra on the peering project). | `string` | `"us-central1"` | no |
| location\_gcs | Case-Sensitive Location for GCS Bucket (Should be same region as the KMS Keyring) | `string` | `"US"` | no |
| location\_kms | Case-Sensitive Location for KMS Keyring (Should be same region as the GCS Bucket) | `string` | `"us"` | no |
| peering\_module\_depends\_on | List of modules or resources peering module depends on. | `list(any)` | `[]` | no |
| remote\_state\_bucket | Backend bucket to load Terraform Remote State Data from previous steps. | `string` | n/a | yes |
| tfc\_org\_name | Name of the TFC organization | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| enable\_cloudbuild\_deploy | Enable infra deployment using Cloud Build. |
| machine\_learning\_kms\_keys | Key ID for the machine learning project. |
| machine\_learning\_project\_id | Project machine learning project. |
| machine\_learning\_project\_number | Project number of machine learning project. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
