# Machine Learning Cloud Key Management Service Keyrings Module

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| keyring\_admins | IAM members that shall be granted admin on the keyring. Format needs to specify member type, i.e. 'serviceAccount:', 'user:', or 'group:' | `list(string)` | n/a | yes |
| keyring\_name | Name to be used for Cloud Key Management Service (KMS) Keyring | `string` | `"sample-keyring"` | no |
| keyring\_regions | Regions to create keyrings in | `list(string)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| prevent\_destroy | Wether to prevent keyring destruction. Must be set to true if the user wants to avoid accidental terraform deletions. | `string` | `"false"` | no |
| project\_id | Project where the resource will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| key\_rings | Keyring Names created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
