# Composer

## Requirements

- Githup Cloud Build App installed. `https://github.com/settings/installations`
- Github repository created.
- Github Token secret version created on Secret Manager. `https://console.cloud.google.com/security/secret-manager/secret/github-api-token/versions?project=ML_PROJECT_ID`
- Composer SA created.

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys| COM-CO-2.3| SC-12 <br />SC-13| PR.DS-1.1 <br /> PR.DS-2.1 <br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| airflow\_config\_overrides | Airflow configuration properties to override. Property keys contain the section and property names, separated by a hyphen, for example "core-dags\_are\_paused\_at\_creation". | `map(string)` | `{}` | no |
| env\_variables | Additional environment variables to provide to the Apache Airflow scheduler, worker, and webserver processes. Environment variable names must match the regular expression [a-zA-Z\_][a-zA-Z0-9\_]*. They cannot specify Apache Airflow software configuration overrides (they cannot match the regular expression AIRFLOW\_\_[A-Z0-9\_]+\_\_[A-Z0-9\_]+), and they cannot match any of the following reserved names: [AIRFLOW\_HOME,C\_FORCE\_ROOT,CONTAINER\_NAME,DAGS\_FOLDER,GCP\_PROJECT,GCS\_BUCKET,GKE\_CLUSTER\_NAME,SQL\_DATABASE,SQL\_INSTANCE,SQL\_PASSWORD,SQL\_PROJECT,SQL\_REGION,SQL\_USER]. | `map(any)` | `{}` | no |
| github\_app\_installation\_id | The app installation ID that was created when installing Google Cloud Build in GitHub: https://github.com/apps/google-cloud-build. | `number` | n/a | yes |
| github\_name\_prefix | A name for your GitHub connection to Cloud Build. | `string` | `"github-modules"` | no |
| github\_remote\_uri | URL of your GitHub repo. | `string` | n/a | yes |
| github\_secret\_name | Name of the GitHub secret to extract GitHub token info. | `string` | `"github-api-token"` | no |
| image\_version | The version of the Airflow running in the Cloud Composer environment. | `string` | `"composer-2.5.2-airflow-2.6.3"` | no |
| kms\_key\_name | The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step" | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| labels | The resource labels (a map of key/value pairs) to be applied to the Cloud Composer. | `map(string)` | `{}` | no |
| maintenance\_window | The configuration settings for Cloud Composer maintenance window. | <pre>object({<br>    start_time = string<br>    end_time   = string<br>    recurrence = string<br>  })</pre> | <pre>{<br>  "end_time": "2021-01-01T13:00:00Z",<br>  "recurrence": "FREQ=WEEKLY;BYDAY=SU",<br>  "start_time": "2021-01-01T01:00:00Z"<br>}</pre> | no |
| name | Name of the Composer environment. | `string` | n/a | yes |
| project\_id | Project ID where Cloud Composer Environment is created. | `string` | n/a | yes |
| pypi\_packages | Custom Python Package Index (PyPI) packages to be installed in the environment. Keys refer to the lowercase package name (e.g. "numpy"). | `map(string)` | `{}` | no |
| python\_version | The default version of Python used to run the Airflow scheduler, worker, and webserver processes. | `string` | `"3"` | no |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| service\_account\_prefix | Name prefix to use for service accounts. | `string` | `"sa"` | no |
| web\_server\_allowed\_ip\_ranges | The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions will be applied. | <pre>list(object({<br>    value       = string<br>    description = string<br>  }))</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| airflow\_uri | URI of the Apache Airflow Web UI hosted within the Cloud Composer Environment. |
| composer\_env\_id | ID of Cloud Composer Environment. |
| composer\_env\_name | Name of the Cloud Composer Environment. |
| gcs\_bucket | Google Cloud Storage bucket which hosts DAGs for the Cloud Composer Environment. |
| gke\_cluster | Google Kubernetes Engine cluster used to run the Cloud Composer Environment. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Troubleshooting

- Error: googleapi: Error 400: Composer API Service Agent service account (service-ML_PROJECT_NUMBER@cloudcomposer-accounts.iam.gserviceaccount.com) does not have required permissions set. Cloud Composer v2 API Service Agent Extension role might be missing. Please refer to https://cloud.google.com/composer/docs/composer-2/create-environments#grant-permissions and Composer Creation Troubleshooting pages to resolve this issue., failedPrecondition

```bash
gcloud projects add-iam-policy-binding ML_PROJECT_NUMBER --member=serviceAccount:service-ML_PROJECT_NUMBER@cloudcomposer-accounts.iam.gserviceaccount.com --role=roles/composer.ServiceAgentV2Ext
```

- If Service Agent cannot use encryption key, grant `roles/cloudkms.cryptoKeyEncrypterDecrypter` for each of the following identities on the key:

```txt
service-$ML_PROJECT_NUMBER@cloudcomposer-accounts.iam.gserviceaccount.com
service-$ML_PROJECT_NUMBER@gcp-sa-artifactregistry.iam.gserviceaccount.com
service-$ML_PROJECT_NUMBER@container-engine-robot.iam.gserviceaccount.com
service-$ML_PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com
service-$ML_PROJECT_NUMBER@compute-system.iam.gserviceaccount.com
service-$ML_PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com
```
