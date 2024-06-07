<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| github\_app\_installation\_id | The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build | `number` | n/a | yes |
| github\_remote\_uri | The remote uri of your github repository | `string` | n/a | yes |
| instance\_region | The region where notebook instance will be created. A subnetwork must exists in the instance region. | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load remote state information from previous steps. | `string` | n/a | yes |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
