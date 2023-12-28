<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance\_region | The region where compute instance will be created. A subnetwork must exists in the instance region. | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load remote state information from previous steps. | `string` | n/a | yes |
| github_api_token | The access token to your GitHub environment | `string` | n/a | yes |
| github_app_installation_id | The installation ID of your Cloud Build GitHub App. Installation is the numberical vlaue | `number` | n/a | yes |
| github_remote_uri | The full URI of the GitHub repository the pipeline will be triggering from | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| trigger_sa_account_id | Account ID of service account cloudbuild|
| cloudbuild_v2_repo_id | Repository ID of cloudbuild repository |
| kms_key_id | Projects Key ID for encrytion |
| artifact_registry_repository_id | Artifact Registry's Repository ID |
| cloudbuild_trigger_id | Cloud Build Trigger ID |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
