# Standalone Example

The Standalone Example deploys the core Enterprise GenAI Blueprint into a single project for the purposes of simplified demonstration.

This example also creates the resources required to deploy the blueprint that are expected to be provided by the user. We call these resources the *external harness*.

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
  - Cloud KMS crypto keys for Artifact Publish and Service Catalog environments.
- The creation of a related Logging bucket in the Logging project.
- The configuration of Private DNS zones for secure, internal Jupyter Notebook access.
- The configuration of the Machine Learning Environment Service Accounts and their IAM bindings.
- The deployment of an Artifact Publish environment, including Artifact Registry for containerized ML pipelines and Cloud Build triggers.
- The deployment of a Service Catalog environment for deploying ML solutions.

**Note:** To deploy this example, you must have an existing project or folder where you can create a service account to deploy the example. This service account must be granted the required IAM roles. In accordance with the principle of separation of concerns, the project should not be in the same folder as the projects created in this example.

## Google Cloud Locations

This example is deployed in the `us-central1` location by default. To deploy in another location, change the `region`, `default_region`, and `instance_region` in your `terraform.tfvars` file. By default, the blueprint has an Organization Policy that only allows the creation of resources in `us-locations`. To deploy in other locations, update the `allowed_locations` input in the main module call.

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
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="examples/standalone/" output -raw artifact_publish_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

2. Clone the newly created Cloud Source Repository:

   ```bash
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```

3. Copy the artifact files, commit, and push:

   ```bash
   cd publish-artifacts
   git checkout -b main
   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../examples/standalone/assets/artifact-publish/ .
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
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="examples/standalone/" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

2. Clone the newly created Cloud Source Repository:

   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

3. Copy the service catalog files, commit, and push:

   ```bash
   cd service-catalog/
   git checkout -b main
   cp -RT ../examples/standalone/assets/service-catalog/ .
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
   export backend_bucket=$(terraform output -raw state_bucket)
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
   *Note: `bucket_force_destroy` must have been set to `true` during the `apply` phase for this command to work successfully.*

   ```bash
   terraform destroy
   ```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_context\_manager\_policy\_id | The id of the default Access Context Manager policy. Can be obtained by running `gcloud access-context-manager policies list --organization YOUR-ORGANIZATION_ID --filter="title='Organization access level policy'" --format="value(name)"`. | `number` | n/a | yes |
| access\_level\_name | Access context manager access level name for the enforced perimeter. | `string` | `""` | no |
| access\_level\_name\_dry\_run | Access context manager access level name for the dry-run perimeter. | `string` | `""` | no |
| artifact\_publish\_project\_name | Custom project name for the artifact publish project. | `string` | `""` | no |
| billing\_account | The billing account id associated with the projects, e.g. XXXXXX-YYYYYY-ZZZZZZ. | `string` | n/a | yes |
| bucket\_force\_destroy | When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| cloud\_source\_artifacts\_repo\_name | Name to give the could source repository for Artifacts | `string` | n/a | yes |
| cloud\_source\_service\_catalog\_repo\_name | Name to give the cloud source repository for Service Catalog | `string` | n/a | yes |
| custom\_restricted\_services | List of services to restrict in an enforced perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected. | `list(string)` | `[]` | no |
| custom\_restricted\_services\_dry\_run | List of custom services to be protected by the dry-run VPC-SC perimeter. If empty, all supported services (https://cloud.google.com/vpc-service-controls/docs/supported-products) will be protected. | `list(string)` | `[]` | no |
| default\_region | Subnetwork region | `string` | `"us-central1"` | no |
| egress\_policies | n/a | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| egress\_policies\_dry\_run | n/a | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| enforce\_vpcsc | Enable the enforced mode for VPC Service Controls. It is not recommended to enable VPC-SC on the first run deploying your foundation. Review [best practices for enabling VPC Service Controls](https://cloud.google.com/vpc-service-controls/docs/enable), then only enforce the perimeter after you have analyzed the access patterns in your dry-run perimeter and created the necessary exceptions for your use cases. | `bool` | `false` | no |
| gcs\_bucket\_prefix | Bucket Prefix | `string` | `"bkt"` | no |
| gcs\_logging\_bucket\_location | Location of environment logging bucket | `string` | `"us-central1"` | no |
| ingress\_policies | n/a | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| ingress\_policies\_dry\_run | n/a | <pre>list(object({<br>    from = any<br>    to   = any<br>  }))</pre> | `[]` | no |
| instance\_region | Compute instance region | `string` | `"us-central1"` | no |
| keyring\_name | Name to be used for KMS Keyring | `string` | `"sample-keyring"` | no |
| keyring\_regions | Regions to create keyrings in | `list(string)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| kms\_prevent\_destroy | If set to true, delete KMS keyring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present. | `bool` | `true` | no |
| kms\_project\_name | Custom project name for kms project. | `string` | `""` | no |
| logging\_project\_name | Custom project name for the logging project. | `string` | `""` | no |
| machine\_learning\_project\_name | Custom project name for machine learning project. | `string` | `""` | no |
| org\_id | The numeric organization id. | `string` | n/a | yes |
| parent\_folder | The folder to deploy in. | `string` | n/a | yes |
| perimeter\_additional\_members | The list additional members to be added on perimeter access. Prefix user: (user:email@email.com) or serviceAccount: (serviceAccount:my-service-account@email.com) is required. | `list(string)` | `[]` | no |
| private\_service\_connect\_ip | Internal IP to be used as the private service connect endpoint. | `string` | `"10.10.64.5"` | no |
| project\_deletion\_policy | Project deletion policy. | `string` | `"PREVENT"` | no |
| region | The GCP region to use when deploying resources | `string` | `"us-central1"` | no |
| restricted\_network\_self\_link | The URI of the machine learning VPC being created. | `list(string)` | `[]` | no |
| seed\_project\_name | Custom project name for seed Project. | `string` | `""` | no |
| service\_catalog\_project\_name | Custom project name for the service catalog project. | `string` | `""` | no |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. | `string` | n/a | yes |
| vpc\_sc\_propagation\_sleep\_duration | The duration to wait for VPC Service Controls propagation (e.g., 60s, 2m). | `string` | `"60s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| access\_level\_name | Access context manager access level name for the enforced perimeter |
| access\_level\_name\_dry\_run | Access context manager access level name for the dry-run perimeter |
| allow\_ingress\_firewall\_rule\_ip\_range | Firewall rules |
| artifact\_publish\_cloudbuild\_trigger\_id | n/a |
| artifact\_publish\_project\_id | Artifact Publish project ID. |
| artifact\_publish\_project\_name | Artifact Publish project Name. |
| artifact\_publish\_project\_number | Artifact Publish project number |
| artifacts\_repo\_id | ID of the Artifacts repository |
| cloud\_source\_artifacts\_repo\_name | Artifacts cloud source repository name. |
| cloud\_source\_service\_catalog\_repo\_name | Service Catalog cloud source repository name. |
| keyring\_name | Key Ring name |
| keyrings\_regions | KMS Keyring region. |
| kms\_keyrings | KMS keyring. |
| kms\_keys | Projects Key ID for encrytion |
| kms\_project\_id | Project ID for Cloud Key Management Service (KMS). |
| kms\_project\_number | Project number for Cloud Key Management Service (KMS). |
| log\_bucket | Log bucket to be used by Service Catalog Bucket. |
| logging\_project\_id | Loggin project ID. |
| logging\_project\_name | Logging Project name |
| machine\_learning\_network\_name | The name of the machine learning VPC being created. |
| machine\_learning\_project\_id | Machine Learning Project ID. |
| machine\_learning\_project\_name | Machine Learning project Name. |
| machine\_learning\_subnets\_self\_link | The self-links of the machine learning subnets being created. |
| parent\_resource\_id | The parent resource id |
| restricted\_network\_self\_link | The URI of the machine learning VPC being created. |
| seed\_project\_id | Artifact Publish project ID. |
| service\_catalog\_cloudbuild\_trigger\_id | n/a |
| service\_catalog\_project\_id | Project ID for Service Catalog. |
| service\_catalog\_project\_name | Service Catalog project number. |
| service\_catalog\_repo\_id | ID of the Service Catalog repository |
| service\_perimeter\_name | Perimeter name. |
| state\_bucket | State bucket |
| storage\_bucket\_name | Name of storage bucket created |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
