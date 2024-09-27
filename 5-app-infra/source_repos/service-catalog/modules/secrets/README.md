## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys| COM-CO-2.3| SC-12 <br />SC-13 | PR.DS-1.1 <br />PR.DS-2.1<br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
|Automatic Secret Replication| SM-CO-6.1| SC-12 <br /> SC-13| None | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Set up Automatic Rotation of Secrets| SM-CO-6.2| SC-12 <br /> SC-13| None | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kms\_key\_name | The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step" | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| secret\_names | Names of the secrets to be created. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| secret\_manager | Secret Manager resource. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
