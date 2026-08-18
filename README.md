# terraform-google-enterprise-genai

## Overview

This repository serves as a example for configuring an environment for the development and deployment of Machine Learning applications using the Vertex AI platform on Google Cloud. It seamlessly integrates the Cloud Foundation Toolkit (CFT) and implements robust security measures, drawing heavily from the [terraform-example-foundation v4.1.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.1.0) codebase.

The repository is divided into distinct Terraform projects, each located in its own directory. These projects must be applied separately but in sequence. For detailed information about each step, please refer to [terraform-example-foundation v4.1.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.1.0). The user has two options when deploying this codebase:

- Following the individual project steps as outlined in this repository, under `0-bootstrap` to `5-appinfra` directories.
- Deploy the codebase on top of an existing Enterprise Foundations Blueprint instance by following the steps detailed in [`docs/deploy_on_foundation_v4.1.0.md`](./docs/deploy_on_foundation_v4.1.0.md).
  > NOTE: If the user currently does not have a Enterprise Foundations Blueprint deployed, he can follow the steps outlined in [terraform-example-foundation v4.1.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.1.0) to deploy it.

## Main Modifications made to Enterprise Foundations Blueprint

- [1. org](./1-org/)
  - Specific to this repository, it will also configure Machine Learning Organization Policies.
  - Create Organization Level Keyring.
- [2. environments](./2-environments/)
  - This repository will also establish organization and environment-level Cloud Key Management Service (KMS) keyrings during this stage.
  - Create support for environment-level logging.
- [3. networks-svpc](./3-networks-svpc/)
  - On this repository, it will also configure a private DNS zone for workbench instances to use either `private.googleapis.com` or `restricted.googleapis.com`.
  - Custom Firewall Rules (`allow_all_ingress_ranges` and `allow_all_egress_ranges`).
  - Enable Cloud NAT.
  - Attach Environment-level Logging Project and Environment-level KMS Project to VPC-SC Perimeter.
- [4. projects](./4-projects/)
  - Instead of creating `business_unit_1` and `business_unit_2`, this repository will create `ml_business_unit`.
  - Additionally, it will establish a Service Catalog project capable of hosting terraform solutions and an Artifacts project, both under the `common` folder.
  - Will create a Machine Learning project for each environment, that is inside a VPC-SC Perimeter and can be used for deploying Machine Learning Workloads.
- [5. app-infra](./5-app-infra/)
  - Deploys a Service Catalog Pipeline, that can be used for packaging terraform modules.
  - Creates an Artifacts Pipeline, that can be used to create organization-wide custom docker images.

## Examples

- [genai-rag-multimodal](./examples/genai-rag-multimodal)
  - Multimodal RAG by performing Q&A over a financial document filled with both text and images.
  - Use RAGAS for RAG chain evaluation.

- [machine-learning-pipeline](./examples/machine-learning-pipeline)
  - This example, adds an interactive coding and experimentation, deploying the Vertex Workbench for data scientists.
  - The step will guide you through creating a ML pipeline using a notebook on Google Vertex AI Workbench Instance.
  - After promoting the ML pipeline, it is triggered by Cloud Build upon staging branch merges, trains and deploys a model using the census income dataset.
  - Model deployment and monitoring occur in the prod environment.
  - Following successful pipeline runs, a new model version is deployed for A/B testing.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_context\_manager\_policy\_id | The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format="value(name)"`. | `number` | n/a | yes |
| access\_level\_name | The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format="value(name)"`. | `string` | `""` | no |
| access\_level\_name\_dry\_run | The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --format="value(name)"`. | `string` | `""` | no |
| allow\_all\_egress\_ranges | List of network ranges to which all egress traffic will be allowed. | `any` | `null` | no |
| allow\_all\_ingress\_ranges | List of network ranges from which all ingress traffic will be allowed. | `any` | `null` | no |
| artifact\_publish\_project\_id | Artifact publishing project ID for Machine Learning projects. | `string` | n/a | yes |
| artifact\_publish\_project\_name | Artifact publishing project name. | `string` | n/a | yes |
| artifact\_publish\_project\_number | Artifact publishing project number for Machine Learning projects. | `string` | n/a | yes |
| billing\_account | The billing account ID associated with the projects, e.g. XXXXXX-YYYYYY-ZZZZZZ. | `string` | n/a | yes |
| bucket\_force\_destroy | When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets that contain objects. | `bool` | `false` | no |
| cloud\_source\_artifacts\_repo\_name | Name to give the Cloud Source repository for artifacts. | `string` | `"publish-artifacts"` | no |
| cloud\_source\_service\_catalog\_repo\_name | Name to give the Cloud Source repository for Service Catalog. | `string` | `"service-catalog"` | no |
| custom\_restricted\_services | List of services to restrict in an enforced perimeter. | `list(string)` | `[]` | no |
| custom\_restricted\_services\_dry\_run | List of custom services to be protected by the dry-run VPC-SC perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected. | `list(string)` | `[]` | no |
| egress\_policies | A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference) to use in an enforced perimeter. Each list object has a `from` and `to` value that describes egress\_from and egress\_to.<br><br>Example: `[{ from={ identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions). | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| egress\_policies\_dry\_run | A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes egress\_from and egress\_to.<br><br>Example: `[{ from={ identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions). | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| egress\_policies\_keys | A list of keys to use for the Terraform state. The order should correspond to var.egress\_policies and the keys must not be dynamically computed. If `null`, var.egress\_policies will be used as keys. | `list(string)` | `[]` | no |
| egress\_policies\_keys\_dry\_run | (Dry-run) A list of keys to use for the Terraform state. The order should correspond to var.egress\_policies\_dry\_run and the keys must not be dynamically computed. If `null`, var.egress\_policies\_dry\_run will be used as keys. | `list(string)` | `[]` | no |
| enforce\_vpcsc | Enable the enforced mode for VPC Service Controls. It is not recommended to enable VPC-SC on the first run deploying your foundation. Review [best practices for enabling VPC Service Controls](https://cloud.google.com/vpc-service-controls/docs/enable), then only enforce the perimeter after you have analyzed the access patterns in your dry-run perimeter and created the necessary exceptions for your use cases. | `bool` | `false` | no |
| firewall\_enable\_logging | Toggle firewall logging for VPC firewalls. | `bool` | `true` | no |
| folder\_id | The folder to deploy in. | `string` | n/a | yes |
| gcs\_bucket\_prefix | Name prefix to be used for GCS Bucket. | `string` | `"bkt"` | no |
| gcs\_logging\_bucket\_location | Location of the environment logging bucket. | `string` | `"us-central1"` | no |
| gcs\_logging\_retention\_period | Retention configuration for the environment logging bucket. | <pre>object({<br>    is_locked             = bool<br>    retention_period_days = number<br>  })</pre> | `null` | no |
| ingress\_policies | A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in an enforced perimeter. Each list object has a `from` and `to` value that describes ingress\_from and ingress\_to.<br><br>Example: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions). | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| ingress\_policies\_dry\_run | A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes ingress\_from and ingress\_to.<br><br>Example: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow identities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [specific services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions). | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| ingress\_policies\_keys | A list of keys to use for the Terraform state. The order should correspond to var.ingress\_policies and the keys must not be dynamically computed. If `null`, var.ingress\_policies will be used as keys. | `list(string)` | `[]` | no |
| ingress\_policies\_keys\_dry\_run | (Dry-run) A list of keys to use for the Terraform state. The order should correspond to var.ingress\_policies\_dry\_run and the keys must not be dynamically computed. If `null`, var.ingress\_policies\_dry\_run will be used as keys. | `list(string)` | `[]` | no |
| instance\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| key\_rotation\_period | Rotation period in seconds to be used for the KMS key. | `string` | `"7776000s"` | no |
| keyring\_admins | IAM members that shall be granted admin on the key ring. Format must specify member type, i.e. 'serviceAccount:', 'user:', 'group:'. | `list(string)` | n/a | yes |
| keyring\_name | Name to be used for the KMS key ring. | `string` | `"sample-keyring"` | no |
| keyring\_regions | Regions to create key rings in. | `list(string)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| keys | Key names. | `list(string)` | `[]` | no |
| kms\_prevent\_destroy | If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present. | `bool` | `true` | no |
| kms\_project\_id | KMS project ID. | `string` | n/a | yes |
| kms\_project\_number | KMS project number. | `string` | n/a | yes |
| labels | (Optional) Labels attached to Machine Learning resources. | `map(string)` | `{}` | no |
| logging\_project\_id | Logging project ID. | `string` | n/a | yes |
| logging\_project\_name | Logging project name. | `string` | n/a | yes |
| logging\_project\_number | Logging project number. | `string` | n/a | yes |
| machine\_learning\_perimeter | Existing Machine Learning perimeter to be used instead of the auto-created perimeter. The service account provided in the variable `terraform_service_account` must be in an access level member list for this perimeter **before** this perimeter can be used in this module. | `string` | `""` | no |
| machine\_learning\_project\_id | Machine Learning project ID. | `string` | n/a | yes |
| machine\_learning\_project\_name | Machine Learning project name. | `string` | n/a | yes |
| machine\_learning\_project\_number | Machine Learning project number. | `string` | n/a | yes |
| network\_name | Network name. | `string` | n/a | yes |
| org\_id | The numeric organization ID. | `string` | n/a | yes |
| perimeter\_additional\_members | The list of additional members to be added to the enforced perimeter access level members list. Prefix user: (user:email@email.com) or serviceAccount: (serviceAccount:my-service-account@email.com) is required. | `list(string)` | `[]` | no |
| perimeter\_additional\_members\_dry\_run | The list of additional members to be added to the dry-run perimeter access level members list. To be able to see the resources protected by the VPC Service Controls in the restricted perimeter, add your user in this list. Entries must be in the standard GCP form: `user:email@example.com` or `serviceAccount:my-service-account@example.com`. | `list(string)` | `[]` | no |
| private\_service\_connect\_ip | Internal IP to be used as the Private Service Connect endpoint. | `string` | `"10.10.64.5"` | no |
| private\_visibility\_config\_networks | List of VPC self links that can see this zone. | `list(string)` | n/a | yes |
| projects\_deletion\_policy | Project deletion policy. Possible values are: "PREVENT", "ABANDON", "DELETE". | `string` | `"PREVENT"` | no |
| restricted\_network\_self\_link | The URI of the Machine Learning VPC being created. | `list(string)` | `[]` | no |
| seed\_project\_id | Seed project ID. | `string` | `""` | no |
| seed\_project\_name | Seed project name. | `string` | `""` | no |
| service\_catalog\_project\_id | Service Catalog project ID. | `string` | n/a | yes |
| service\_catalog\_project\_name | Service Catalog project name. | `string` | n/a | yes |
| service\_catalog\_project\_number | Service Catalog project number. | `string` | n/a | yes |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. | `string` | n/a | yes |
| vpc\_sc\_propagation\_sleep\_duration | The duration to wait for VPC Service Controls propagation (e.g., 60s, 2m). | `string` | `"60s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| access\_context\_manager\_policy\_id | Access Context Manager policy ID. |
| access\_level\_name | Access Context Manager access level name. |
| access\_level\_name\_dry\_run | Access Context Manager access level name for the dry-run perimeter. |
| allow\_ingress\_firewall\_rule\_ip\_range | IP range for the allow ingress firewall rule. |
| artifact\_publish\_cloudbuild\_trigger\_id | Cloud Build trigger ID for artifact publishing. |
| artifact\_publish\_project\_id | Artifact publishing project ID. |
| artifacts\_repo\_id | ID of the artifacts repository. |
| cloud\_source\_artifacts\_repo\_name | Cloud Source repository name for artifact publishing. |
| cloud\_source\_service\_catalog\_repo\_name | Cloud Source repository name for Service Catalog. |
| key\_rings | Key ring names created. |
| kms\_keys | KMS keys created by region and project. |
| kms\_project\_id | Cloud Key Management Service (KMS) project ID. |
| log\_bucket | Log bucket to be used by Service Catalog. |
| logging\_project\_id | Logging project ID. |
| service\_catalog\_cloudbuild\_trigger\_id | Cloud Build trigger ID for Service Catalog. |
| service\_catalog\_project\_id | Service Catalog project ID. |
| service\_catalog\_repo\_id | ID of the Service Catalog repository. |
| service\_perimeter\_name | Service perimeter name. |
| storage\_bucket\_name | Name of the storage bucket created. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
