<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| monitoring\_workspace\_users | Google Workspace or Cloud Identity group that have access to Monitoring Workspaces. | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load Terraform Remote State Data from previous steps. | `string` | n/a | yes |
| tfc\_org\_name | Name of the TFC organization | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| env\_folder | Environment folder created under parent. |
| env\_kms\_project\_id | Project for environment Cloud Key Management Service (KMS). |
| env\_kms\_project\_number | Project Number for environment Cloud Key Management Service (KMS). |
| env\_log\_bucket\_name | Name of environment log bucket |
| env\_log\_project\_id | Project ID of the environments log project |
| env\_log\_project\_number | Project Number of the environments log project |
| env\_secrets\_project\_id | Project for environment related secrets. |
| key\_rings | Keyring Names created |
| monitoring\_project\_id | Project for monitoring infra. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
