<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kms\_key\_name | The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step" | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| name | The name of the metadata store instance. | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vertex\_ai\_metadata\_store | Vertex AI Metadata Store. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
