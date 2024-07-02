<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance\_region | The region where compute instance will be created. A subnetwork must exists in the instance region. | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load remote state information from previous steps. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_trigger\_id | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
