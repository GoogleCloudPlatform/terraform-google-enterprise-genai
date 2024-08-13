# 5-app-infra

This repo is part of a multi-part guide that shows how to configure and deploy
the example.com reference architecture described in
[Google Cloud security foundations guide](https://cloud.google.com/architecture/security-foundations). The following table lists the parts of the guide.

<table>
<tbody>
<tr>
<td><a href="../0-bootstrap">0-bootstrap</a></td>
<td>Bootstraps a Google Cloud organization, creating all the required resources
and permissions to start using the Cloud Foundation Toolkit (CFT). This
step also configures a <a href="../docs/GLOSSARY.md#foundation-cicd-pipeline">CI/CD Pipeline</a> for foundations code in subsequent
stages.</td>
</tr>
<tr>
<td><a href="../1-org">1-org</a></td>
<td>Sets up top-level shared folders, monitoring and networking projects,
organization-level logging, and baseline security settings through
organizational policies.</td>
</tr>
<tr>
<td><a href="../2-environments"><span style="white-space: nowrap;">2-environments</span></a></td>
<td>Sets up development, non-production, and production environments within the
Google Cloud organization that you've created.</td>
</tr>
<tr>
<td><a href="../3-networks-dual-svpc">3-networks-dual-svpc</a></td>
<td>Sets up base and restricted shared VPCs with default DNS, NAT (optional),
Private Service networking, VPC service controls, on-premises Dedicated
Interconnect, and baseline firewall rules for each environment. It also sets
up the global DNS hub.</td>
</tr>
<tr>
<td><a href="../4-projects">4-projects</a></td>
<td>Sets up a folder structure, projects, and an application infrastructure pipeline for applications,
 which are connected as service projects to the shared VPC created in the previous stage.</td>
</tr>
<tr>
<td>5-app-infra (this file)</td>
<td>A project folder structure which expands upon all projects created in 4-projects</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-google-enterprise-genai README](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai)
file.

## Purpose

Inside the `projects` folder, the `artifact-publish` and `service-catalog` directories contain applications that will be further developed. These directories are Terraform repositories that house the configuration code for their respective applications. For instance, in the `projects/artifact-publish` directory, you will find code that configures the custom pipeline for the artifact-publish application.
> Note: Remember that in step 4-projects, the Service Catalog and Artifacts projects were created under `common` folder.

Inside the `source_repos` folder, the folders `artifact-publish` and `service-catalog` are seperate Cloud Build Repositories that have their own unique piplelines configured. These are used for building out in-house Docker images for your machine-learning pipelines and terraform modules that can be deployed through the Service Catalog Google Cloud Product.

This repository contain examples using modules in `notebooks` in your interactive (development) environment, as well as deployment modules for your operational (non-production, production) environments respectively.

For the purposes of this demonstration, we assume that you are using Cloud Build or manual deployment.

## Prerequisites

1. 0-bootstrap executed successfully.
1. 1-org executed successfully.
1. 2-environments executed successfully.
1. 3-networks executed successfully.
1. 4-projects executed successfully.

### Troubleshooting

Please refer to [troubleshooting](../docs/TROUBLESHOOTING.md) if you run into issues during this step.

## Usage

**Note:** If you are using MacOS, replace `cp -RT` with `cp -R` in the relevant
commands. The `-T` flag is needed for Linux, but causes problems for MacOS.

### Deploying with Cloud Build

1. Ensure you are in a neutral directory outside any other git related repositories.

1. Clone the `gcp-policies` repo based on the Terraform output from the `4-projects` step.
Clone the repo at the same level of the `terraform-google-enterprise-genai` folder, the following instructions assume this layout.
Run `terraform output cloudbuild_project_id` in the `4-projects` folder to get the Cloud Build Project ID.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   gcloud source repos clone gcp-policies gcp-policies-app-infra --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

   **Note:** `gcp-policies` repo has the same name as the repo created in step `1-org`. In order to prevent a collision, the previous command will clone this repo in the folder `gcp-policies-app-infra`.

1. Navigate into the repo and copy contents of policy-library to new repo. All subsequent steps assume you are running them
   from the gcp-policies-app-infra directory. If you run them from another directory,
   adjust your copy paths accordingly.

   ```bash
   cd gcp-policies-app-infra/
   git checkout -b main

   cp -RT ../terraform-google-enterprise-genai/policy-library/ .
   ```

1. Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Initialize policy library repo'

   git push --set-upstream origin main
   ```

1. Navigate out of the repo.

   ```bash
   cd ..
   ```

#### Artifacts Application

The purpose of this step is to deploy out an artifact registry to store custom docker images. A Cloud Build pipeline is also deployed out. At the time of this writing, it is configured to attach itself to a Cloud Source Repository. The Cloud Build pipeline is responsible for building out a custom image that may be used in Machine Learning Workflows.  If you are in a situation where company policy requires no outside repositories to be accessed, custom images can be used to keep access to any image internally.

Since every workflow will have access to these images, it is deployed in the `common` folder, and keeping with the foundations structure, is listed as `shared` under this Business Unit.  It will only need to be deployed once.

The Pipeline is connected to a Google Cloud Source Repository with a simple structure:

   ```
   ├── README.md
   └── images
      ├── tf2-cpu.2-13:0.1
      │   └── Dockerfile
      └── tf2-gpu.2-13:0.1
         └── Dockerfile
   ```
for the purposes of this example, the pipeline is configured to monitor the `main` branch of this repository.

each folder under `images` has the full name and tag of the image that must be built.  Once a change to the `main` branch is pushed, the pipeline will analyse which files have changed and build that image out and place it in the artifact repository.  For example, if there is a change to the Dockerfile in the `tf2-cpu-13:0.1` folder, or if the folder itself has been renamed, it will build out an image and tag it based on the folder name that the Dockerfile has been housed in.

Once pushed, the pipeline build logs can be accessed by navigating to the artifacts project name created in step-4:

   ```bash
   terraform -chdir="gcp-projects/ml_business_unit/shared/" output -raw common_artifacts_project_id
   ```

1. Clone the `ml-artifact-publish` repo.

   ```bash
   gcloud source repos clone ml-artifact-publish --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of genAI to new repo.
   All subsequent steps assume you are running them from the ml-artifact-publish directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd ml-artifact-publish/
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/artifact-publish/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the file with values from your environment and 0-bootstrap. See machine learning business unit env folder [README.md](./ml_business_unit/production/README.md) file for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize repo'
   ```

1. Push your plan branch to trigger a plan for all environments. Because the
   _plan_ branch is not a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing your _plan_
   branch triggers _terraform plan_ but not _terraform apply_. Review the plan output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git push --set-upstream origin plan
   ```

1. Merge changes to shared. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch),
   pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git checkout -b production
   git push origin production
   ```

1. `cd` out of the `ml-artifacts-publish` repository.

   ```bash
   cd ..
   ```

1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.

#### Configuring Cloud Source Repository of Artifact Application

1. Grab the Artifact Project ID

   ```bash
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared" output -raw common_artifacts_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```

1. Enter the repo folder and copy over the artifact files from `5-app-infra/source_repos/artifact-publish` folder.

   ```bash
   cd publish-artifacts
   git checkout -b main

   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/artifact-publish/ .
   ```

1. Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Build Images'

   git push --set-upstream origin main
   ```

1. `cd` out of the `publish-artifacts` repository.

   ```bash
   cd ..
   ```

#### Service Catalog Pipeline Configuration

This step has two main purposes:

1. To deploy a pipeline and a bucket which is linked to a Google Cloud Repository that houses terraform modules for the use in Service Catalog.
Although Service Catalog itself must be manually deployed, the modules which will be used can still be automated.

2. To deploy infrastructure for operational environments (ie. `non-production` & `production`.)

The resoning behind utilizing one repository with two deployment methodologies is due to how close interactive (`development`) and operational environments are.

The repository has the structure (truncated for brevity):

   ```
   ml_business_unit
   ├── development
   ├── non-production
   ├── production
   modules
   ├── bucket
   │   ├── README.md
   │   ├── data.tf
   │   ├── main.tf
   │   ├── outputs.tf
   │   ├── provider.tf
   │   └── variables.tf
   ├── composer
   │   ├── README.md
   │   ├── data.tf
   │   ├── iam.roles.tf
   │   ├── iam.users.tf
   │   ├── locals.tf
   │   ├── main.tf
   │   ├── outputs.tf
   │   ├── provider.tf
   │   ├── terraform.tfvars.example
   │   ├── variables.tf
   │   └── vpc.tf
   ├── cryptography
   │   ├── README.md
   │   ├── crypto_key
   │   │   ├── main.tf
   │   │   ├── outputs.tf
   │   │   └── variables.tf
   │   └── key_ring
   │       ├── main.tf
   │       ├── outputs.tf
   │       └── variables.tf
   ```

Each folder under `modules` represents a terraform module.
When there is a change in any of the terraform module folders, the pipeline will find whichever module has been changed since the last push, `tar.gz` that file and place it in a bucket for Service Catalog to access.

This pipeline is listening to the `main` branch of this repository for changes in order for the modules to be uploaded to service catalog.

The pipeline also listens for changes made to `plan`, `development`, `non-production` & `production` branches, this is used for deploying infrastructure to each project.

1. Clone the `ml-service-catalog` repo.

   ```bash
   gcloud source repos clone ml-service-catalog --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of foundation to new repo.
   All subsequent steps assume you are running them from the ml-service-catalog directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd ml-service-catalog
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/service-catalog/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./ml_business_unit/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-service-catalog"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update the `log_bucket` variable with the value of the `logs_export_storage_bucket_name`.

   ```bash
   terraform -chdir="../gcp-org/envs/shared" init
   export log_bucket=$(terraform -chdir="../gcp-org/envs/shared" output -raw logs_export_storage_bucket_name)
   echo "log_bucket = ${log_bucket}"
   sed -i "s/REPLACE_LOG_BUCKET/${log_bucket}/" ./common.auto.tfvars
   ```

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize repo'
   ```

1. Push your plan branch to trigger a plan for all environments. Because the
   _plan_ branch is not a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing your _plan_
   branch triggers _terraform plan_ but not _terraform apply_. Review the plan output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git push --set-upstream origin plan
   ```

1. Merge changes to production. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch),
   pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git checkout -b production
   git push origin production
   ```

1. `cd` out of the `ml-service-catalog` repository.

   ```bash
   cd ..
   ```

#### Configuring Cloud Source Repository of Service Catalog Solutions Pipeline

1. Grab the Service Catalogs ID

   ```bash
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Enter the repo folder and copy over the service catalogs files from `5-app-infra/source_repos/service-catalog` folder.

   ```bash
   cd service-catalog/
   git checkout -b main
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/service-catalog/ .
   git add img
   git commit -m "Add img directory"
   ```

1. Commit changes and push main branch to the new repo.

   ```bash
   git add modules
   git commit -m 'Initialize Service Catalog Build Repo'

   git push --set-upstream origin main
   ```

1. `cd` out of the `service_catalog` repository.

   ```bash
   cd ..
   ```

1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.

### Run Terraform locally

#### Artifacts Application

1. Create `ml-artifact-publish` directory at the same level as `terraform-google-enterprise-genai`.

   ```bash
   mkdir ml-artifact-publish
   ```

1. Navigate into the repo, change to non-main branch and copy contents of genAI to new repo.
   All subsequent steps assume you are running them from the ml-artifact-publish directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd ml-artifact-publish/

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/artifact-publish/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` files to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your environment.

1. Use `terraform output` to get the project backend bucket value from 0-bootstrap.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Provide the user that will be running `./tf-wrapper.sh` the Service Account Token Creator role to the ml Terraform service account.

1. Provide the user permissions to run the terraform locally with the `serviceAccountTokenCreator` permission.

   ```bash
   member="user:$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")"
   echo ${member}

   project_id=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${project_id}

   terraform_sa=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json terraform_service_accounts | jq '."ml-artifact-publish"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `5-app-infra` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json terraform_service_accounts | jq '."ml-artifact-publish"' --raw-output)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared (common).

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1.  Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/../terraform-google-enterprise-genai/policy-library ${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Run `apply` shared.

   ```bash
   ./tf-wrapper.sh apply shared
   ```

If you received any errors or made any changes to the Terraform config or `common.auto.tfvars` you must re-run `./tf-wrapper.sh plan <env>` before running `./tf-wrapper.sh apply <env>`.

After executing this stage, unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

```bash
unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
```

1. `cd` out of the repository.

   ```bash
   cd ..
   ```

#### Configuring Cloud Source Repository of Artifact Application

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder.

1. Grab the Artifact Project ID

   ```bash
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="terraform-google-enterprise-genai/4-projects/ml_business_unit/shared" output -raw common_artifacts_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```

1. Enter the repo folder and copy over the artifact files from `5-app-infra/source_repos/artifact-publish` folder.

   ```bash
   cd publish-artifacts
   git checkout -b main

   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/artifact-publish/ .
   ```

1. Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Build Images'

   git push --set-upstream origin main
   ```

1. `cd` out of the `publish-artifacts` repository.

   ```bash
   cd ..
   ```

#### Service Catalog Configuration


1. Create `ml-service-catalog` directory at the same level as `terraform-google-enterprise-genai`.

   ```bash
   mkdir ml-service-catalog
   ```

1. Navigate into the repo, change to non-main branch and copy contents of foundation to new repo.
   All subsequent steps assume you are running them from the ml-service-catalog directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd ml-service-catalog

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/service-catalog/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./ml_business_unit/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-service-catalog"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update the `log_bucket` variable with the value of the `logs_export_storage_bucket_name`.

   ```bash
   export log_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/1-org/envs/shared" output -raw logs_export_storage_bucket_name)
   echo "log_bucket = ${log_bucket}"
   sed -i "s/REPLACE_LOG_BUCKET/${log_bucket}/" ./common.auto.tfvars
   ```

1. Provide the user permissions to run the terraform locally with the `serviceAccountTokenCreator` permission.

   ```bash
   (cd ../terraform-google-enterprise-genai/4-projects && ./tf-wrapper.sh init shared)

   member="user:$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")"
   echo ${member}

   project_id=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${project_id}

   terraform_sa=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json terraform_service_accounts | jq '."ml-service-catalog"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `5-app-infra` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../terraform-google-enterprise-genai/4-projects/ml_business_unit/shared/" output -json terraform_service_accounts | jq '."ml-service-catalog"' --raw-output)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared (common).

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/../terraform-google-enterprise-genai/policy-library ${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Run `apply` shared.

   ```bash
   ./tf-wrapper.sh apply shared
   ```

If you received any errors or made any changes to the Terraform config or `common.auto.tfvars` you must re-run `./tf-wrapper.sh plan <env>` before running `./tf-wrapper.sh apply <env>`.

After executing this stage, unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

   ```bash
   unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
   ```

1. `cd` out of the repository.

   ```bash
   cd ..
   ```

#### Configuring Cloud Source Repository of Service Catalog Solutions Pipeline

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder

1. Grab the Service Catalogs ID

   ```bash
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="terraform-google-enterprise-genai/4-projects/ml_business_unit/shared" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Enter the repo folder and copy over the service catalogs files from `5-app-infra/source_repos/service-catalog` folder.

   ```bash
   cd service-catalog/
   git checkout -b main

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/service-catalog/ .
   git add img
   git commit -m "Add img directory"
   ```

1. Commit changes and push main branch to the new repo.

   ```bash
   git add modules
   git commit -m 'Initialize Service Catalog Build Repo'

   git push --set-upstream origin main
   ```

1. `cd` out of the `service-catalog` repository.

   ```bash
   cd ..
   ```

1. Navigate to the project that was output from `${SERVICE_CATALOG_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built: https://console.cloud.google.com/cloud-build/builds;region=us-central1?orgonly=true&project=${SERVICE_CATALOG_PROJECT_ID}&supportedpurview=project
