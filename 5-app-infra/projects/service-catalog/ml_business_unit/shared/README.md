<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance\_region | The region where compute instance will be created. A subnetwork must exists in the instance region. | `string` | `"us-central1"` | no |
| log\_bucket | Log bucket to be used by Service Catalog Bucket | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load remote state information from previous steps. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_trigger\_id | Id of Cloud Build Trigger |
| storage\_bucket\_name | Name of storage bucket created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
