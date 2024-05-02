<!-- BEGIN_TF_DOCS -->
Copyright 2024 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-google-modules/network/google | ~> 8.1 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_cloudbuildv2_connection.repo_connect](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloudbuildv2_connection) | resource |
| [google-beta_google_cloudbuildv2_repository.repo](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloudbuildv2_repository) | resource |
| [google-beta_google_composer_environment.cluster](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_composer_environment) | resource |
| [google_cloudbuild_trigger.zip_files](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger) | resource |
| [google_secret_manager_secret_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_policy) | resource |
| [google_service_account.trigger_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.trigger_sa_impersonate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [random_shuffle.zones](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [google_iam_policy.serviceagent_secretAccessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_netblock_ip_ranges.health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.iap_forwarders](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.legacy_health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |
| [google_pubsub_topic.secret_rotations](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/pubsub_topic) | data source |
| [google_secret_manager_secret.github_api_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret) | data source |
| [google_secret_manager_secret_version.github_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |
| [google_service_account.composer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_airflow_config_overrides"></a> [airflow\_config\_overrides](#input\_airflow\_config\_overrides) | Airflow configuration properties to override. Property keys contain the section and property names, separated by a hyphen, for example "core-dags\_are\_paused\_at\_creation". | `map(string)` | `{}` | no |
| <a name="input_env_variables"></a> [env\_variables](#input\_env\_variables) | Additional environment variables to provide to the Apache Airflow scheduler, worker, and webserver processes. Environment variable names must match the regular expression [a-zA-Z\_][a-zA-Z0-9\_]*. They cannot specify Apache Airflow software configuration overrides (they cannot match the regular expression AIRFLOW\_\_[A-Z0-9\_]+\_\_[A-Z0-9\_]+), and they cannot match any of the following reserved names: [AIRFLOW\_HOME,C\_FORCE\_ROOT,CONTAINER\_NAME,DAGS\_FOLDER,GCP\_PROJECT,GCS\_BUCKET,GKE\_CLUSTER\_NAME,SQL\_DATABASE,SQL\_INSTANCE,SQL\_PASSWORD,SQL\_PROJECT,SQL\_REGION,SQL\_USER] | `map(any)` | `{}` | no |
| <a name="input_github_app_installation_id"></a> [github\_app\_installation\_id](#input\_github\_app\_installation\_id) | The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build | `number` | n/a | yes |
| <a name="input_github_name_prefix"></a> [github\_name\_prefix](#input\_github\_name\_prefix) | A name for your github connection to cloubuild | `string` | `"github-modules"` | no |
| <a name="input_github_remote_uri"></a> [github\_remote\_uri](#input\_github\_remote\_uri) | Url of your github repo | `string` | n/a | yes |
| <a name="input_github_secret_name"></a> [github\_secret\_name](#input\_github\_secret\_name) | Name of the github secret to extract github token info | `string` | `"github-api-token"` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | The version of the aiflow running in the cloud composer environment. | `string` | `"composer-2.5.2-airflow-2.6.3"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | The resource labels (a map of key/value pairs) to be applied to the Cloud Composer. | `map(string)` | `{}` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The configuration settings for Cloud Composer maintenance window. | <pre>object({<br>    start_time = string<br>    end_time   = string<br>    recurrence = string<br>  })</pre> | <pre>{<br>  "end_time": "2021-01-01T13:00:00Z",<br>  "recurrence": "FREQ=WEEKLY;BYDAY=SU",<br>  "start_time": "2021-01-01T01:00:00Z"<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | name of the Composer environment | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional project ID where Cloud Composer Environment is created. | `string` | `null` | no |
| <a name="input_pypi_packages"></a> [pypi\_packages](#input\_pypi\_packages) | Custom Python Package Index (PyPI) packages to be installed in the environment. Keys refer to the lowercase package name (e.g. "numpy"). | `map(string)` | `{}` | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The default version of Python used to run the Airflow scheduler, worker, and webserver processes. | `string` | `"3"` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| <a name="input_service_account_prefix"></a> [service\_account\_prefix](#input\_service\_account\_prefix) | Name prefix to use for service accounts. | `string` | `"sa"` | no |
| <a name="input_web_server_allowed_ip_ranges"></a> [web\_server\_allowed\_ip\_ranges](#input\_web\_server\_allowed\_ip\_ranges) | The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions will be applied. | <pre>list(object({<br>    value       = string<br>    description = string<br>  }))</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_airflow_uri"></a> [airflow\_uri](#output\_airflow\_uri) | URI of the Apache Airflow Web UI hosted within the Cloud Composer Environment. |
| <a name="output_composer_env_id"></a> [composer\_env\_id](#output\_composer\_env\_id) | ID of Cloud Composer Environment. |
| <a name="output_composer_env_name"></a> [composer\_env\_name](#output\_composer\_env\_name) | Name of the Cloud Composer Environment. |
| <a name="output_gcs_bucket"></a> [gcs\_bucket](#output\_gcs\_bucket) | Google Cloud Storage bucket which hosts DAGs for the Cloud Composer Environment. |
| <a name="output_gke_cluster"></a> [gke\_cluster](#output\_gke\_cluster) | Google Kubernetes Engine cluster used to run the Cloud Composer Environment. |
<!-- END_TF_DOCS -->

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys| COM-CO-2.3| SC-12 <br />SC-13| PR.DS-1.1 <br /> PR.DS-2.1 <br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
<<<<<<< HEAD
=======
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| airflow\_config\_overrides | Airflow configuration properties to override. Property keys contain the section and property names, separated by a hyphen, for example "core-dags\_are\_paused\_at\_creation". | `map(string)` | `{}` | no |
| env\_variables | Additional environment variables to provide to the Apache Airflow scheduler, worker, and webserver processes. Environment variable names must match the regular expression [a-zA-Z\_][a-zA-Z0-9\_]*. They cannot specify Apache Airflow software configuration overrides (they cannot match the regular expression AIRFLOW\_\_[A-Z0-9\_]+\_\_[A-Z0-9\_]+), and they cannot match any of the following reserved names: [AIRFLOW\_HOME,C\_FORCE\_ROOT,CONTAINER\_NAME,DAGS\_FOLDER,GCP\_PROJECT,GCS\_BUCKET,GKE\_CLUSTER\_NAME,SQL\_DATABASE,SQL\_INSTANCE,SQL\_PASSWORD,SQL\_PROJECT,SQL\_REGION,SQL\_USER] | `map(any)` | `{}` | no |
| github\_app\_installation\_id | The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build | `number` | n/a | yes |
| github\_name\_prefix | A name for your github connection to cloubuild | `string` | `"github-modules"` | no |
| github\_remote\_uri | Url of your github repo | `string` | n/a | yes |
| github\_secret\_name | Name of the github secret to extract github token info | `string` | `"github-api-token"` | no |
| image\_version | The version of the aiflow running in the cloud composer environment. | `string` | `"composer-2.5.2-airflow-2.6.3"` | no |
| labels | The resource labels (a map of key/value pairs) to be applied to the Cloud Composer. | `map(string)` | `{}` | no |
| maintenance\_window | The configuration settings for Cloud Composer maintenance window. | <pre>object({<br>    start_time = string<br>    end_time   = string<br>    recurrence = string<br>  })</pre> | <pre>{<br>  "end_time": "2021-01-01T13:00:00Z",<br>  "recurrence": "FREQ=WEEKLY;BYDAY=SU",<br>  "start_time": "2021-01-01T01:00:00Z"<br>}</pre> | no |
| name | name of the Composer environment | `string` | n/a | yes |
| project\_id | Optional project ID where Cloud Composer Environment is created. | `string` | `null` | no |
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
>>>>>>> main
