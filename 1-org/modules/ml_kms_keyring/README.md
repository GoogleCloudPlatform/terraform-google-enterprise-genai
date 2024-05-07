# ML KMS Keyrings Module

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| keyring\_admins | IAM members that shall be granted admin on the keyring. Format need to specify member type, i.e. 'serviceAccount:', 'user:', 'group:' | `list(string)` | n/a | yes |
| keyring\_name | Name to be used for KMS Keyring | `string` | `"sample-keyring"` | no |
| keyring\_regions | Regions to create keyrings in | `list(string)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| project\_id | Project where the resource will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| key\_rings | Keyring Names created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
