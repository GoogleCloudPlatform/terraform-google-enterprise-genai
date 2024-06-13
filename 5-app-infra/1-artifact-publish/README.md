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
<td><a href="../3-networks-hub-and-spoke">3-networks-hub-and-spoke</a></td>
<td>Sets up base and restricted shared VPCs with all the default configuration
found on step 3-networks-dual-svpc, but here the architecture will be based on the
Hub and Spoke network model. It also sets up the global DNS hub</td>
</tr>
<tr>
<td><a href="../4-projects">4-projects</a></td>
<td>Sets up a folder structure, projects, and an application infrastructure pipeline for applications,
 which are connected as service projects to the shared VPC created in the previous stage.</td>
</tr>
<tr>
<td>5-app-infra 01-artifact-publish(this file)</td>
<td>Deploys Artifact Repository</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-google-enterprise-genai README](https://github.com/terraform-google-modules/terraform-google-enterprise-genai)
file.

## Purpose

The purpose of this step is to deploy out an artifact registry to store custom docker images. A Cloud Build pipeline is also deployed out.  At the time of this writing, it is configured to attach itself to a Cloud Source Repository. The Cloud Build pipeline is responsible for building out a custom image that may be used in Machine Learning Workflows.  If you are in a situation where company policy requires no outside repositories to be accessed, custom images can be used to keep access to any image internally.

Since every workflow will have access to these images, it is deployed in the `common` folder, and keeping with the foundations structure, is listed as `shared` under this Business Unit.  It will only need to be deployed once.

The Pipeline is connected to a GitHub repsository with a simple structure:

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

Once pushed, the pipeline can be accessed by navigating to the project name created in step-4:

```bash
terraform -chdir="../terraform-google-enterprise-genai/4-projects/business_unit_3/shared/" output -raw common_artifacts_project_id
```

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

1. Clone the `bu3-artifact-publish` repo.

   ```bash
   gcloud source repos clone bu3-artifact-publish --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of foundation to new repo.
   All subsequent steps assume you are running them from the bu3-artifact-publisg directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd bu3-artifact-publish
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/1-artifact-publish/ .
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


### Run Terraform locally

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

