# Standalone Example

This examples deploys the Enterprise GenAI blueprint.

This example also creates the resources required to deploy the blueprint that are expected to be provided by the user. We call these resources the _external harness_.

The External Harness includes:

- The creation of the six GCP projects needed by the Blueprint:
  - Seed project
  - KMS project
  - Logging project
  - Machine Learning project
  - Artifact Publish project
  - Service Catalog project
- A Cloud Storage bucket for remote Terraform state storage in the Seed project.
- The creation of a VPC Network to deploy Vertex AI Notebooks and ML workloads in the Machine Learning project. The network includes:
  - A VPC Network with one restricted subnetwork.
  - Tag-based routes for internet access.

[Custom names](#inputs) can be provided for the six projects created in this example. If custom names are not provided, the default project names will be:

- `prj-seed`
- `prj-logging`
- `prj-kms`
- `prj-machine-learning`
- `prj-artifact-publish`
- `prj-service-catalog`

A random suffix is added to the end of the names to create unique project IDs and prevent collisions with existing projects.

The Blueprint deployment includes:

- The deployment of the [main module](../../main.tf) itself.
- The configuration of Organization Policies to restrict unapproved services, enforce specific TLS versions, and whitelist allowed Vertex AI notebook base images and access modes.
- The Cloud KMS infrastructure for Customer-Managed Encryption Keys (CMEK):
  - A Cloud KMS Keyring.
  - Cloud KMS crypto keys for Logging, Artifact Publish and Service Catalog projects.
- The creation of a related Logging bucket in the Logging project.
- The configuration of Private DNS zones for secure, internal Jupyter Notebook access.
- The configuration of the Machine Learning environment.
- The deployment of an Artifact Publish environment, including Artifact Registry for containerized machine learning pipelines and Cloud Build triggers.
- The deployment of a Service Catalog environment for deploying machine learning solutions.

**Note:** To deploy this example, you must have an existing project or folder where you can create a service account to deploy the example. This service account must be granted the required IAM roles. In accordance with the principle of separation of concerns, the project should not be in the same folder as the projects created in this example.

## Prerequisites and Service Account Setup

To provision the resources for this example, you must create a privileged service account. The service account key cannot be created. Consider using Cloud Monitoring to alert on this service account's activity.

The user utilizing this service account must have the `Service Account User` and `Service Account Token Creator` roles to [impersonate](https://cloud.google.com/iam/docs/impersonating-service-accounts) the service account.

You can use the [Project Factory module](https://github.com/terraform-google-modules/terraform-google-project-factory) and the [IAM module](https://github.com/terraform-google-modules/terraform-google-iam) to provision a service account with the necessary roles.

Grant the following roles to the service account:

### Organization Level Roles

- Access Context Manager Admin: `roles/accesscontextmanager.policyAdmin`
- Billing Account User: `roles/billing.user`
- Organization Policy Administrator: `roles/orgpolicy.policyAdmin`
- Organization Administrator: `roles/resourcemanager.organizationAdmin`

### Folder Level Roles

- Compute Network Admin: `roles/compute.networkAdmin`
- Compute Security Admin: `roles/compute.securityAdmin`
- DNS Administrator: `roles/dns.admin`
- Logging Admin: `roles/logging.admin`
- Project Creator: `roles/resourcemanager.projectCreator`
- Project Deleter: `roles/resourcemanager.projectDeleter`
- Project IAM Admin: `roles/resourcemanager.projectIamAdmin`
- Folder Admin: `roles/resourcemanager.folderAdmin`
- Pub/Sub Admin: `roles/pubsub.admin`
- Service Account Admin: `roles/iam.serviceAccountAdmin`
- Service Usage Admin: `roles/serviceusage.serviceUsageAdmin`
- Serverless VPC Access Admin: `roles/vpcaccess.admin`

## Google Cloud Locations

This example is deployed in the `us-central1` location by default. To deploy in another location, change the `default_region` in your `terraform.tfvars` file. By default, the blueprint has an Organization Policy that only allows the creation of resources in `us-locations`. To deploy in other locations, update the `allowed_locations` input in the main module call.

## Usage

1. Rename the `tfvars` example file and update it with values for your environment:

   ```bash
   mv terraform.example.tfvars terraform.tfvars
   ```

2. Initialize Terraform to download the required plugins:

   ```bash
   terraform init
   ```

3. Review the Terraform plan:

   ```bash
   terraform plan
   ```

4. Apply the infrastructure build:

   ```bash
   terraform apply
   ```

### Configuring Cloud Source Repository of Artifact Application

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder.

1. Retrieve the Artifact Project ID:

   ```bash
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="terraform-google-enterprise-genai/examples/standalone/" output -raw artifact_publish_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

1. Clone the newly created Cloud Source Repository:

   ```bash
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```

1. Copy the artifact files, commit, and push:

   ```bash
   cd publish-artifacts
   git checkout -b main
   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../terraform-google-enterprise-genai/examples/standalone/assets/artifact-publish/ .
   git add .
   git commit -m 'Build Images'
   git push --set-upstream origin main
   cd ..
   ```

1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the build running.

### Configuring the Service Catalog Repository

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder.

1. Retrieve the Service Catalog Project ID:

   ```bash
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="terraform-google-enterprise-genai/examples/standalone/" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Clone the newly created Cloud Source Repository:

   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Copy the service catalog files, commit, and push:

   ```bash
   cd service-catalog/
   git checkout -b main
   cp -RT ../terraform-google-enterprise-genai/examples/standalone/assets/service-catalog/ .
   git add img
   git commit -m "Add img directory"
   git add modules
   git commit -m 'Initialize Service Catalog Build Repo'
   git push --set-upstream origin main
   cd ..
   ```

1. Navigate to the project that was output from `${SERVICE_CATALOG_PROJECT_ID}` in Google's Cloud Console to view the build running.

### Migrating Terraform State to Remote GCS Backend

After local deployment, migrate the Terraform state to the remote GCS backend using the `backend.tf` configuration.

1. Navigate to the standalone example directory and retrieve the GCS bucket name:

   ```bash
   cd examples/standalone
   export backend_bucket=$(terraform output -raw remote_state_bucket)
   echo "backend_bucket = ${backend_bucket}"
   ```

2. Rename `backend.tf.example` to `backend.tf` and update it with the bucket name:

   ```bash
   mv backend.tf.example backend.tf
   sed -i "s|UPDATE_ME|${backend_bucket}|g" backend.tf
   ```

3. Re-initialize Terraform and agree to copy the state to Cloud Storage:

   ```bash
   terraform init
   ```

4. (Optional) Run `terraform plan` to verify the state configuration. There should be no changes from the previous state.

## Troubleshooting

If you encounter problems during the `apply` execution, please refer to the [Troubleshooting Guide](../../docs/TROUBLESHOOTING.md).

## Clean Up

**CRITICAL:** Before destroying your environment, you MUST migrate your Terraform state back to your local machine. Because the Terraform state is stored inside the GCS bucket provisioned by this infrastructure, Terraform will fail if it tries to delete the bucket while it holds the active state.

1. Disable the remote backend and pull the state locally:

   ```bash
   mv backend.tf backend.tf.disabled
   terraform init -migrate-state
   # Type 'yes' when prompted to copy the state back locally
   ls -la terraform.tfstate
   ```

2. Destroy the environment:
   _Note: `bucket_force_destroy` must be set to `true`, and `kms_prevent_destroy` must be set to `false` during the `apply` phase for this command to work successfully._

   ```bash
   terraform destroy
   ```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_context\_manager\_policy\_id | The ID of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --filter="title='Organization access level policy'" --format="value(name)"`. | `number` | n/a | yes |
| access\_level\_name | Access Context Manager access level name for the enforced perimeter. | `string` | `""` | no |
| access\_level\_name\_dry\_run | Access Context Manager access level name for the dry-run perimeter. | `string` | `""` | no |
| artifact\_publish\_project\_name | Custom project name for the artifact publishing project. | `string` | `""` | no |
| billing\_account | The billing account ID associated with the projects, e.g. XXXXXX-YYYYYY-ZZZZZZ. | `string` | n/a | yes |
| bucket\_force\_destroy | When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets that contain objects. | `bool` | `false` | no |
| cloud\_source\_artifacts\_repo\_name | Name to give the Cloud Source repository for artifacts. | `string` | n/a | yes |
| cloud\_source\_service\_catalog\_repo\_name | Name to give the Cloud Source repository for Service Catalog. | `string` | n/a | yes |
| custom\_restricted\_services | List of services to restrict in an enforced perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected. | `list(string)` | `[]` | no |
| custom\_restricted\_services\_dry\_run | List of custom services to be protected by the dry-run VPC-SC perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected. | `list(string)` | `[]` | no |
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| egress\_policies | A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference), each list object has a `from` and `to` value that describes egress\_from and egress\_to.<br><br>Example: `[{ from={ identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid Values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| egress\_policies\_dry\_run | A list of all [egress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#egress-rules-reference), each list object has a `from` and `to` value that describes egress\_from and egress\_to.<br><br>Example: `[{ from={ identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid Values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| encrypt\_gcs\_bucket\_tfstate | Encrypt the bucket used for storing Terraform state files in the seed project. | `bool` | `true` | no |
| enforce\_vpcsc | Enable the enforced mode for VPC Service Controls. It is not recommended to enable VPC-SC on the first run deploying your foundation. Review [best practices for enabling VPC Service Controls](https://cloud.google.com/vpc-service-controls/docs/enable), then only enforce the perimeter after you have analyzed the access patterns in your dry-run perimeter and created the necessary exceptions for your use cases. | `bool` | `false` | no |
| gcs\_bucket\_prefix | Name prefix to be used for the GCS bucket. | `string` | `"bkt"` | no |
| gcs\_logging\_bucket\_location | Location of the environment logging bucket. | `string` | `"us-central1"` | no |
| ingress\_policies | A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference), each list object has a `from` and `to` value that describes ingress\_from and ingress\_to.<br><br>Example: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid Values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| ingress\_policies\_dry\_run | A list of all [ingress policies](https://cloud.google.com/vpc-service-controls/docs/ingress-egress-rules#ingress-rules-reference) to use in a dry-run perimeter. Each list object has a `from` and `to` value that describes ingress\_from and ingress\_to.<br><br>Example: `[{ from={ sources={ resources=[], access_levels=[] }, identities=[], identity_type="ID_TYPE" }, to={ resources=[], operations={ "SRV_NAME"={ OP_TYPE=[] }}}}]`<br><br>Valid Values:<br>`ID_TYPE` = `null` or `IDENTITY_TYPE_UNSPECIFIED` (only allow indentities from list); `ANY_IDENTITY`; `ANY_USER_ACCOUNT`; `ANY_SERVICE_ACCOUNT`<br>`SRV_NAME` = "`*`" (allow all services) or [Specific Services](https://cloud.google.com/vpc-service-controls/docs/supported-products#supported_products)<br>`OP_TYPE` = [methods](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) or [permissions](https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions) | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| keyring\_name | Name to be used for the KMS key ring. | `string` | `"sample-keyring"` | no |
| keyring\_regions | Regions to create key rings in. | `list(string)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| kms\_prevent\_destroy | If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present. | `bool` | `true` | no |
| kms\_project\_name | Custom project name for the KMS project. | `string` | `""` | no |
| logging\_project\_name | Custom project name for the logging project. | `string` | `""` | no |
| machine\_learning\_project\_name | Custom project name for the Machine Learning project. | `string` | `""` | no |
| nat\_bgp\_asn | BGP ASN for NAT cloud route. This is needed to allow the Jenkins Agent to download packages and updates from the internet without having an external IP address. | `number` | `64512` | no |
| org\_id | The numeric organization ID. | `string` | n/a | yes |
| parent\_folder | The folder to deploy in. | `string` | n/a | yes |
| perimeter\_additional\_members | The list of additional members to be added to the enforced perimeter access level members list. Prefix user: (user:email@email.com) or serviceAccount: (serviceAccount:my-service-account@email.com) is required. | `list(string)` | `[]` | no |
| perimeter\_additional\_members\_dry\_run | The list of additional members to be added to the dry-run perimeter access level members list. To be able to see the resources protected by the VPC Service Controls in the restricted perimeter, add your user in this list. Entries must be in the standard GCP form: `user:email@example.com` or `serviceAccount:my-service-account@example.com`. | `list(string)` | `[]` | no |
| private\_service\_connect\_ip | Internal IP to be used as the Private Service Connect endpoint. | `string` | `"10.10.64.5"` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |
| project\_prefix | Name prefix to use for projects created. Should be the same in all steps. Max size is 3 characters. | `string` | `"prj"` | no |
| restricted\_network\_self\_link | The URI of the Machine Learning VPC being created. | `list(string)` | `[]` | no |
| seed\_project\_name | Custom project name for the seed project. | `string` | `""` | no |
| service\_catalog\_project\_name | Custom project name for the Service Catalog project. | `string` | `""` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. | `string` | n/a | yes |
| vpc\_sc\_propagation\_sleep\_duration | The duration to wait for VPC Service Controls propagation (e.g., 60s, 2m). | `string` | `"60s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| access\_level\_name | Access Context Manager access level name for the enforced perimeter. |
| access\_level\_name\_dry\_run | Access Context Manager access level name for the dry-run perimeter. |
| allow\_ingress\_firewall\_rule\_ip\_range | Allow ingress firewall rule IP range. |
| artifact\_publish\_cloudbuild\_trigger\_id | Artifact publishing Cloud Build trigger ID. |
| artifact\_publish\_project\_id | Artifact publishing project ID. |
| artifact\_publish\_project\_name | Artifact publishing project name. |
| artifact\_publish\_project\_number | Artifact publishing project number. |
| artifacts\_repo\_id | Artifacts repository ID. |
| cloud\_source\_artifacts\_repo\_name | Artifacts Cloud Source repository name. |
| cloud\_source\_service\_catalog\_repo\_name | Service Catalog Cloud Source repository name. |
| instance\_region | Region where the resources were created. |
| keyring\_name | Key ring name. |
| keyrings\_regions | KMS key ring regions. |
| kms\_keyrings | KMS key rings. |
| kms\_keys | KMS key IDs for encryption. |
| kms\_project\_id | Cloud Key Management Service (KMS) project ID. |
| kms\_project\_number | Cloud Key Management Service (KMS) project number. |
| log\_bucket | Log bucket to be used by Service Catalog. |
| logging\_project\_id | Logging project ID. |
| logging\_project\_name | Logging project name. |
| machine\_learning\_network\_name | The name of the Machine Learning VPC being created. |
| machine\_learning\_project\_id | Machine Learning project ID. |
| machine\_learning\_project\_name | Machine Learning project name. |
| machine\_learning\_subnets\_self\_link | The self-links of the Machine Learning subnets being created. |
| parent\_resource\_id | The parent resource ID. |
| remote\_state\_bucket | Bucket used for storing Terraform state for the standalone example in the seed project. |
| restricted\_network\_self\_link | The URI of the Machine Learning VPC being created. |
| seed\_project\_id | Seed project ID. |
| service\_catalog\_cloudbuild\_trigger\_id | Service Catalog Cloud Build trigger ID. |
| service\_catalog\_project\_id | Service Catalog project ID. |
| service\_catalog\_project\_name | Service Catalog project name. |
| service\_catalog\_repo\_id | ID of the Service Catalog repository. |
| service\_perimeter\_name | Access Context Manager service perimeter name. |
| storage\_bucket\_name | Name of the storage bucket created. |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
