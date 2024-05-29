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

Folders `1-artifact-publish`, `3-serive-catalog` and `5-machine-learning` are projects that will be _expanded_ upon.  In step 4, we have initiated the creation of these projects, enabled API's and assigned roles to various service accounts, service agents and cryptography keys that are needed for each respective project to operate successfully.  Folders `2-artifact-publish-repo` and `4-service-catalog-repo` are seperate cloud build repositories that have their own unique piplelines configured. These are used for building out in-house Docker images for your machine-learning pipelines and terraform modules that will be used in `notebooks` in your interactive (development) environment, as well as deployment modules for your operational (non-production, production) environments respectively.

For the purposes of this demonstration, we assume that you are using Cloud Build or manual deployment.

When viewing each folder under `projects`, consider them as seperate repositories which will be used to deploy out each respective project.  In the case of using Cloud Build (which is what this example is primarily based on), each folder will be placed in its own GCP cloud source repository for deployment.  There is a README placed in each project folder which will highlight the necessary steps to achieve deployment.

When deploying/expanding upon each project, you will find your Cloud Build pipelines being executed in `prj-c-bu3infra-pipeline`.

The order of deployments for the machine-learning's project is as follows:

* 1-artifact-publish
* 2-service-catalog
* 3-artifact-publish-repo
* 4-service-catalog-repo
* 5-vpc-sc
* 7-machine-learning-post-deploy

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

1. Clone the `gcp-policies` repo based on the Terraform output from the `0-bootstrap` step.
Clone the repo at the same level of the `terraform-google-enterprise-genai` folder, the following instructions assume this layout.
Run `terraform output cloudbuild_project_id` in the `0-bootstrap` folder to get the Cloud Build Project ID.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="gcp-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   gcloud source repos clone gcp-policies gcp-policies-app-infra --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

   **Note:** `gcp-policies` repo has the same name as the repo created in step `1-org`. In order to prevent a collision, the previous command will clone this repo in the folder `gcp-policies-app-infra`.

1. Navigate into the repo and copy contents of policy-library to new repo. All subsequent steps assume you are running them
   from the gcp-policies-app-infra directory. If you run them from another directory,
   adjust your copy paths accordingly.

   ```bash
   cd gcp-policies-app-infra
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

#### ARTIFACT PUBLISH

1. Clone the `bu3-artifact-publish` repo.

   ```bash
   gcloud source repos clone bu3-artifact-publish --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of genAI to new repo.
   All subsequent steps assume you are running them from the bu3-artifact-publisg directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd bu3-artifact-publish
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/artifact-publish/ .
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./business_unit_1/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-artifact-publish"' --raw-output)
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
   git checkout -b shared
   git push origin shared
   ```

1. `cd` out of the `bu3-artifacts-publish` repository.

   ```bash
   cd ..
   ```

#### SERVICE-CATALOG

1. Clone the `bu3-service-catalog` repo.

   ```bash
   gcloud source repos clone bu3-service-catalog --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of foundation to new repo.
   All subsequent steps assume you are running them from the bu3-service-catalog directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd bu3-service-catalog
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/service-catalog .
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./business_unit_1/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-service-catalog"' --raw-output)
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
   git checkout -b shared
   git push origin shared
   ```

1. `cd` out of the `bu3-service-catalog` repository.
   
   ```bash
   cd ..
   ```

#### ARTIFACT PUBLISH REPO

1. Grab the Artifact Project ID
   ```bash
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="gcp-projects/business_unit_3/shared" output -raw common_artifacts_project_id)
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

1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.

#### SERVICE CATALOG REPO

1. Grab the Service Catalogs ID
  
   ```bash
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="gcp-projects/business_unit_3/shared" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.
   
   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

1. Enter the repo folder and copy over the service catalogs files from `5-app-infra/source_repos` folder.
   
   ```bash
   cd service-catalog
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/modules/svc_ctlg_solutions_repo/ .
   ```

1. Commit changes and push main branch to the new repo.
   
   ```bash
   git add .
   git commit -m 'Initialize Service Catalog Build Repo'

   git push --set-upstream origin main
   ```

1. `cd` out of the `service_catalog` repository.
   
   ```bash
   cd ..
   ```

1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.

### Run Terraform locally

#### ARTIFACT PUBLISH

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder. Change into `5-app-infra` folder, copy the Terraform wrapper script and ensure it can be executed.

   ```bash
   cd terraform-google-enterprise-genai/5-app-infra/projects/artifact-publish
   cp ../../../build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` files to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your environment.

1. Use `terraform output` to get the project backend bucket value from 0-bootstrap.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Provide the user that will be running `./tf-wrapper.sh` the Service Account Token Creator role to the bu3 Terraform service account.
1. Provide the user permissions to run the terraform locally with the `serviceAccountTokenCreator` permission.

   ```bash
   member="user:$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")"
   echo ${member}

   project_id=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${project_id}

   terraform_sa=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-artifact-publish"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `5-app-infra` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../../../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../../../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-artifact-publish"' --raw-output)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared (common).

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/../policy-library ${INFRA_PIPELINE_PROJECT_ID}
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

#### SERVICE-CATALOG

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder. Change into `5-app-infra` folder, copy the Terraform wrapper script and ensure it can be executed.

   ```bash
   cd terraform-google-enterprise-genai/5-app-infra/projects/service-catalog
   cp ../../../build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` files to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your environment.
1. Use `terraform output` to get the project backend bucket value from 0-bootstrap.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Provide the user that will be running `./tf-wrapper.sh` the Service Account Token Creator role to the bu3 Terraform service account.
1. Provide the user permissions to run the terraform locally with the `serviceAccountTokenCreator` permission.

   ```bash
   member="user:$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")"
   echo ${member}

   project_id=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${project_id}

   terraform_sa=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-service-catalog"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-service-catalog"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `5-app-infra` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../../../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../../../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-service-catalog"' --raw-output)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment shared (common).

   ```bash
   ./tf-wrapper.sh init shared
   ./tf-wrapper.sh plan shared
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate shared $(pwd)/../policy-library ${INFRA_PIPELINE_PROJECT_ID}
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

#### VPC-SC

Be aware that for the purposes of this machine learning project, there are several projects in each respective environment that have been placed within a `service perimeter`.
As such, during your deployment process, you _will_ encounter deployment errors related to VPC-SC violations.  Before continuing onto `5-app-infra/projects`, you will need to go _back_ into `3-networks-dual-svpc` and _update_
your ingress rules.

Below, you can find the values that will need to be applied to `common.auto.tfvars` and your `development.auto.tfvars`, ###`non-production.auto.tfvars` & `production.auto.tfvars`.

In `common.auto.tfvars` update your `perimeter_additional_members` to include:
 * the service acccount for bu3infra-pipeline: `"serviceAccount:sa-tf-cb-bu3-machine-learning@[prj-c-bu3infra-pipeline-project-id].iam.gserviceaccount.com"`
 * the service account for your cicd pipeline: `"serviceAccount:sa-terraform-env@[prj-b-seed-project-id].iam.gserviceaccount.com"`
 * your development environment logging bucket service account: `"serviceAccount:service-[prj-d-logging-project-number]@gs-project-accounts.iam.gserviceaccount.com"`
 * your development environment service acount for cloudbuild: `"serviceAccount:[prj-d-machine-learning-project-number]@cloudbuild.gserviceaccount.com"`

 In each respective environment folders, update your `development.auto.tfvars`, `non-production.auto.tfvars` & `production.auto.tfvars` to include the changes mentioned in <a href="./5-vpc-sc/README.md#ingress-policies">Ingress Policies section</a>.

For your DEVELOPMENT.AUTO.TFVARS file, also include the egress policy mentioned in <a href="./5-vpc-sc/README.md#egress-policies">Egress Policies section</a>.

Please note that this will cover some but not ALL the policies that will be needed.  During deployment there will be violations that will occur which come from unknown google projects outside the scope of your organization.  It will be the responsibility of the operator(s) deploying this process to view logs about the errors and make adjustments accordingly.  Most notably, this was observed for Service Catalog.  There will be an instance where an egress policy to be added for `cloudbuild.googleapis.com` access:

    ```
    // Service Catalog
    {
        "from" = {
        "identity_type" = "ANY_IDENTITY"
        "identities"    = []
        },
        "to" = {
        "resources" = ["projects/[some random google project id]"]
        "operations" = {
            "cloudbuild.googleapis.com" = {
            "methods" = ["*"]
            }
        }
        }
    },
    ```
