# Machine Learning Pipeline Overview

This repo is part of a multi-part guide that shows how to configure and deploy
the example.com reference architecture described in
[Google Cloud security foundations guide](https://cloud.google.com/architecture/security-foundations). The following table lists the parts of the guide.

<table>
<tbody>
<tr>
<td><a href="../0-bootstrap/">0-bootstrap</a></td>
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
<td>Machine-learning-pipeline(this file)</td>
<td>Deploys modules based on the modules created in 5-app-infra</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-google-enterprise-genai README](https://github.com/terraform-google-modules/terraform-google-enterprise-genai)
file.

## Purpose

The purpose of this guide is to provide a structured to deploying a machine learning pipeline on Google Cloud Platform using Vertex AI.

## Prerequisites

1. 0-bootstrap executed successfully.
2. 1-org executed successfully.
3. 2-environments executed successfully.
4. 3-networks executed successfully.
5. 4-projects executed successfully.
6. 5-app-infra executed successfully.
7. The step bellow `VPC-SC` executed successfully.

### VPC-SC

By now, `artifact-publish` and `service-catalog` have been deployed. The projects inflated under `machine-learning-pipeline` are set in a service perimiter for added security.  As such, several services and accounts must be given ingress and egress policies before `machine-learning-pipeline` has been deployed.

cd into gcp-networks

  ```bash
  cd gcp-networks/
  ```

Below, you can find the values that will need to be applied to `common.auto.tfvars` and your `development.auto.tfvars`, `non-production.auto.tfvars` & `production.auto.tfvars`.

In `common.auto.tfvars` update your `perimeter_additional_members` to include:

  ```
  "serviceAccount:sa-tf-cb-bu3-machine-learning@[prj_c_bu3infra_pipeline_project_id].iam.gserviceaccount.com"
<<<<<<< HEAD
  "serviceAccount:sa-terraform-env@[prj_b_seed_project_id].iam.gserviceaccount.com",
  "serviceAccount:service-[prj_d_logging_project_number]@gs-project-accounts.iam.gserviceaccount.com",
  "serviceAccount:[prj_d_machine_learning_project_number]@cloudbuild.gserviceaccount.com",
  "serviceAccount:[prj_d_machine_learning_project_number]-compute@developer.gserviceaccount.com",
  "serviceAccount:sa-d-composer@[prj_d_machine_learning_project_id].iam.gserviceaccount.com",
  "serviceAccount:project-service-account@[prj_d_machine_learning_project_id].iam.gserviceaccount.com"
=======
  "serviceAccount:sa-terraform-env@[prj_b_seed_project_id].iam.gserviceaccount.com"
  "serviceAccount:service-[prj_d_logging_project_number]@gs-project-accounts.iam.gserviceaccount.com"
  "serviceAccount:[prj_d_machine_learning_project_number]@cloudbuild.gserviceaccount.com"
>>>>>>> main
  ```

  ```bash
   export prj_c_bu3infra_pipeline_project_id=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo "prj_c_bu3infra_pipeline_project_id = ${prj_c_bu3infra_pipeline_project_id}"

   export prj_b_seed_project_id=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw seed_project_id)
   echo "prj_b_seed_project_id = ${prj_b_seed_project_id}"

   export prj_b_seed_project_id=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw seed_project_id)
   echo "prj_b_seed_project_id = ${prj_b_seed_project_id}"

   export prj_b_seed_project_id=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw seed_project_id)
   echo "prj_b_seed_project_id = ${prj_b_seed_project_id}"

   export backend_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw gcs_bucket_tfstate)
   echo "remote_state_bucket = ${backend_bucket}"

   export backend_bucket_projects=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "backend_bucket_projects = ${backend_bucket_projects}"

   export project_d_logging_project_number=$(gsutil cat gs://$backend_bucket/terraform/environments/development/default.tfstate | jq -r '.outputs.env_log_project_number.value')
   echo "project_d_logging_project_number = ${project_d_logging_project_number}"

   prj_d_machine_learning_project_number=$(gsutil cat gs://$backend_bucket_projects/terraform/projects/business_unit_3/development/default.tfstate | jq -r '.outputs.machine_learning_project_number.value')
   echo "project_d_machine_learning_number = ${prj_d_machine_learning_project_number}"
  ```


In each respective environment folders, update your `development.auto.tfvars`, `non-production.auto.tfvars` & `production.auto.tfvars` to include these changes under `ingress_policies`

You can find the `sources.access_level` information by going to `Security` in your GCP Organization.
Once there, select the perimeter that is associated with the environment (eg. `development`). Copy the string under Perimeter Name and place it under `YOUR_ACCESS_LEVEL`

#### Ingress Policies

  ```
  ingress_policies = [

      // users
      {
          "from" = {
          "identity_type" = "ANY_IDENTITY"
          "sources" = {
              "access_level" = "[YOUR_ACCESS_LEVEL]"
          }
          },
          "to" = {
          "resources" = [
              "projects/[your-environment-shared-restricted-project-number]",
              "projects/[your-environment-kms-project-number]",
              "projects/[your-environment-bu3machine-learning-number]",
          ]
          "operations" = {
<<<<<<< HEAD
            "compute.googleapis.com" = {
            "methods" = ["*"]
            }
            "dns.googleapis.com" = {
            "methods" = ["*"]
            }
            "dataproc.googleapis.com" = {
            "methods" = ["*"]
            }
            "logging.googleapis.com" = {
            "methods" = ["*"]
            }
            "storage.googleapis.com" = {
            "methods" = ["*"]
            }
            "cloudkms.googleapis.com" = {
            "methods" = ["*"]
            }
            "iam.googleapis.com" = {
            "methods" = ["*"]
            }
            "cloudresourcemanager.googleapis.com" = {
            "methods" = ["*"]
            }
            "pubsub.googleapis.com" = {
            "methods" = ["*"]
            }
            "secretmanager.googleapis.com" = {
            "methods" = ["*"]
            }
            "aiplatform.googleapis.com" = {
            "methods" = ["*"]
            }
            "composer.googleapis.com" = {
            "methods" = ["*"]
            }
            "cloudbuild.googleapis.com" = {
            "methods" = ["*"]
            }
            "bigquery.googleapis.com" = {
            "methods" = ["*"]
            }
=======
              "compute.googleapis.com" = {
              "methods" = ["*"]
              }
              "dns.googleapis.com" = {
              "methods" = ["*"]
              }
              "logging.googleapis.com" = {
              "methods" = ["*"]
              }
              "storage.googleapis.com" = {
              "methods" = ["*"]
              }
              "cloudkms.googleapis.com" = {
              "methods" = ["*"]
              }
              "iam.googleapis.com" = {
              "methods" = ["*"]
              }
              "cloudresourcemanager.googleapis.com" = {
              "methods" = ["*"]
              }
              "pubsub.googleapis.com" = {
              "methods" = ["*"]
              }
              "secretmanager.googleapis.com" = {
              "methods" = ["*"]
              }
              "aiplatform.googleapis.com" = {
              "methods" = ["*"]
              }
              "composer.googleapis.com" = {
              "methods" = ["*"]
              }
              "cloudbuild.googleapis.com" = {
              "methods" = ["*"]
              }
              "bigquery.googleapis.com" = {
              "methods" = ["*"]
              }
>>>>>>> main
          }
          }
      },
  ]
  ```

#### Egress Policies

For your DEVELOPMENT.AUTO.TFVARS file, also include this as an egress policy:

  ```bash
    egress_policies = [
        // notebooks
        {
            "from" = {
            "identity_type" = ""
            "identities" = [
                "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@gcp-sa-notebooks.iam.gserviceaccount.com",
                "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@compute-system.iam.gserviceaccount.com",
            ]
            },
            "to" = {
            "resources" = ["projects/[prj-d-kms-project-number]"]
            "operations" = {
                "compute.googleapis.com" = {
                "methods" = ["*"]
                }
                "cloudkms.googleapis.com" = {
                "methods" = ["*"]
                }
            }
            }
        },
    ]
  ```

### Troubleshooting

Please refer to [troubleshooting](../docs/TROUBLESHOOTING.md) if you run into issues during this step.

## Usage

**Note:** If you are using MacOS, replace `cp -RT` with `cp -R` in the relevant
commands. The `-T` flag is needed for Linux, but causes problems for MacOS.

You will need a github repository set up for this step.  This repository houses the DAG's for composer.  As of this writing, the structure is as follows:

   ```
   .
   ├── README.md
   └── dags
      ├── hello_world.py
      └── strings.py
   ```

Add in your dags in the `dags` folder.  Any changes to this folder will trigger a pipeline and place the dags in the appropriate composer environment depending on which branch it is pushed to (`development`, `non-production`, `production`)

Have a github token for access to your repository ready, along with an [Application Installation Id](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github#connecting_a_github_host_programmatically) and the remote uri to your repository.

These environmental project inflations are closely tied to the `service-catalog` project that have already deployed.  By now, the `bu3-service-catalog` should have been inflated.  `service-catalog` contains modules that are being deployed in an interactive (development) environment. Since they already exist; they can be used as terraform modules for operational (non-production, production) environments.  This was done in order to avoid code redundancy. One area for all `machine-learning` deployments.

Under `modules/base_env/main.tf` you will notice all module calls are using `git` links as sources.  These links refer to the `service-catalog` cloud source repository we have already set up.

Step 12 in "Deploying with Cloud Build" highlights the necessary steps needed to point the module resources to the correct location.

### Deploying with Cloud Build

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

1. Clone the `bu3-machine-learning` repo.

   ```bash
   gcloud source repos clone bu3-machine-learning --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Navigate into the repo, change to non-main branch and copy contents of foundation to new repo.
   All subsequent steps assume you are running them from the bu3-machine-learning directory.
   If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd bu3-machine-learning
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/examples/machine-learning-pipeline .
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update the `common.auto.tfvars` file with your github app installation id, along with the url of your repository.

   ```bash
   GITHUB_APP_ID="YOUR-GITHUB-APP-ID-HERE"
   GITHUB_REMOTE_URI="YOUR-GITHUB-REMOTE-URI"

   sed -i "s/GITHUB_APP_ID/${GITHUB_APP_ID}/" ./common.auto.tfvars
   sed -i "s/GITHUB_REMOTE_URI/${GITHUB_REMOTE_URI}/" ./common.auto.tfvars
   ```

1. Use `terraform output` to get the project backend bucket value from 0-bootstrap.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../terraform-google-enterprise-genai/0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Use `terraform output` to retrieve the Service Catalog project-id from the projects step and update values in `module/base_env`.

   ```bash
   export service_catalog_project_id=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -raw service_catalog_project_id)
   echo "service_catalog_project_id = ${service_catalog_project_id}"

   ## Linux
   sed -i "s/SERVICE_CATALOG_PROJECT_ID/${service_catalog_project_id}/g" ./modules/base_env/main.tf
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-machine-learning"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   ## Linux
   for i in `find . -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done

   ## MacOS
   for i in `find . -name 'backend.tf'`; do sed -i "" "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update `modules/base_env/main.tf` with the name of service catalog project id to complete the git fqdn for module sources:

   ```bash
   export service_catalog_project_id=$(terraform -chdir="../gcp-projects/business_unit_3/shared/" output -raw service_catalog_project_id)

   ##LINUX
   sed -i "s/SERVICE-CATALOG-PROJECT-ID/${service_catalog_project_id}/" ./modules/base_env/main.tf

   ##MacOS
   sed -i "" "s/SERVICE-CATALOG-PROJECT-ID/${service_catalog_project_id}/" ./modules/base_env/main.tf
   ```

1. Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize repo'
   ```

1. Composer will rely on DAG's from a github repository.  In `4-projects`, a secret 'github-api-token' was created to house your github's api access key.  We need to create a new version for this secret which will be used in the composer module which is called in the `base_env` folder.  Use the script below to add the secrets into each machine learnings respective environment:

   ```bash
   envs=(development non-production production)
   project_ids=()
   github_token="YOUR-GITHUB-TOKEN"

   for env in "${envs[@]}"; do
      output=$(terraform -chdir="../gcp-projects/business_unit_3/${env}" output -raw machine_learning_project_id)
      project_ids+=("$output")
   done

   for project in "${project_ids[@]}"; do
      echo -n $github_token | gcloud secrets versions add github-api-token --data-file=- --project=${project}
   done
   ```

1. Push your plan branch to trigger a plan for all environments. Because the
   _plan_ branch is not a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing your _plan_
   branch triggers _terraform plan_ but not _terraform apply_. Review the plan output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git push --set-upstream origin plan
   ```

1. Merge changes to development. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch),
   pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```
   git checkout -b development
   git push origin development
   ```

1. Merge changes to non-production. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch),
   pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git checkout -b non-production
   git push origin non-production
   ```

1. Merge changes to production branch. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch),
      pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID

   ```bash
   git checkout -b production
   git push origin production
   ```

1. cd out of this directory

   ```bash
   cd ..
   ```

## Running Terraform locally

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder. Change into `machine-learning-pipeline` folder, copy the Terraform wrapper script and ensure it can be executed.

   ```bash
   cd terraform-google-enterprise-genai/examples/machine-learning-pipeline
   cp ../../build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

1. Rename `common.auto.example.tfvars` files to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

1. Update `common.auto.tfvars` file with values from your environment.

1. Use `terraform output` to get the project backend bucket value from 0-bootstrap.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../../0-bootstrap/" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

1. Provide the user that will be running `./tf-wrapper.sh` the Service Account Token Creator role to the bu3 Terraform service account.

1. Provide the user permissions to run the terraform locally with the `serviceAccountTokenCreator` permission.

   ```bash
   member="user:$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")"
   echo ${member}

   project_id=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${project_id}

   terraform_sa=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-machine-learning"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-machine-learning"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update `modules/base_env/main.tf` with Service Catalog Project Id.

   ```bash
   export service_catalog_project_id=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -raw service_catalog_project_id)
   echo "service_catalog_project_id = ${service_catalog_project_id}"

   ## Linux
   sed -i "s/SERVICE_CATALOG_PROJECT_ID/${service_catalog_project_id}/g" ./modules/base_env/main.tf
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `machine-learning-pipeline` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-machine-learning"' --raw-output)
   echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
   ```

1. Run `init` and `plan` and review output for environment production.

   ```bash
   ./tf-wrapper.sh init production
   ./tf-wrapper.sh plan production
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate production $(pwd)/../policy-library ${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Run `apply` production.

   ```bash
   ./tf-wrapper.sh apply production
   ```

1. Run `init` and `plan` and review output for environment non-production.

   ```bash
   ./tf-wrapper.sh init non-production
   ./tf-wrapper.sh plan non-production
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate non-production $(pwd)/../policy-library ${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Run `apply` non-production.

   ```bash
   ./tf-wrapper.sh apply non-production
   ```

1. Run `init` and `plan` and review output for environment development.

   ```bash
   ./tf-wrapper.sh init development
   ./tf-wrapper.sh plan development
   ```

1. Run `validate` and check for violations.

   ```bash
   ./tf-wrapper.sh validate development $(pwd)/../policy-library ${INFRA_PIPELINE_PROJECT_ID}
   ```

1. Run `apply` development.

   ```bash
   ./tf-wrapper.sh apply development
   ```

If you received any errors or made any changes to the Terraform config or `common.auto.tfvars` you must re-run `./tf-wrapper.sh plan <env>` before running `./tf-wrapper.sh apply <env>`.

After executing this stage, unset the `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable.

  ```bash
  unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
  ```

## Post Deployment

### Big Query

  In order to avoid having to specify a kms key for every query against a bigquery resource, we set the default project encryption key to the corresponding environment key in advance
  ```bash
   ml_project_dev=$(terraform -chdir="gcp-projects/business_unit_3/development" output -json)
   ml_project_nonprd=$(terraform -chdir="gcp-projects/business_unit_3/non-production" output -json)
   ml_project_prd=$(terraform -chdir="gcp-projects/business_unit_3/production" output -json)

  projects=( "$ml_project_dev" "$ml_project_nonprd" "$ml_project_prd" )

  for project in "${projects[@]}"; do
    project_id=$(echo "$project" | jq -r '.machine_learning_project_id.value')
    project_key=$(echo "$project "| jq -r '.machine_learning_kms_keys.value."us-central1".id')
    echo "ALTER PROJECT \`$project_id\` SET OPTIONS (\`region-us-central1.default_kms_key_name\`=\"$project_key\");" | bq query --project_id "$project_id" --nouse_legacy_sql
  done
  ```

### VPC-SC

1. Now that machine learning's projects have all been inflated, please _return to gcp-projects_ and update COMMON.AUTO.TFVARS with this __additional__ information under `perimeter_additional_members`:

    ```
    "serviceAccount:service-[prj-n-bu3machine-learning-number]@dataflow-service-producer-prod.iam.gserviceaccount.com",
    "serviceAccount:[prj-n-bu3machine-learning-number]@cloudbuild.gserviceaccount.com",
    "serviceAccount:[prj-n-bu3machine-learning-number]-compute@developer.gserviceaccount.com",
    "serviceAccount:[prj-p-bu3machine-learning-number]@cloudbuild.gserviceaccount.com",
    "serviceAccount:service-[prj-p-bu3machine-learning-number]@gcp-sa-aiplatform.iam.gserviceaccount.com",
    ```

2. optional - run the below command to generate a list of the above changes needed to COMMON.AUTO.TFVARS

    ```bash
    ml_n=$(terraform -chdir="gcp-projects/business_unit_3/non-production" output -raw machine_learning_project_number)
    ml_p=$(terraform -chdir="gcp-projects/business_unit_3/production" output -raw machine_learning_project_number)

    echo "serviceAccount:service-${ml_n}@dataflow-service-producer-prod.iam.gserviceaccount.com",
    echo "serviceAccount:${ml_n}@cloudbuild.gserviceaccount.com",
    echo "serviceAccount:${ml_n}-compute@developer.gserviceaccount.com",
    echo "serviceAccount:${ml_p}@cloudbuild.gserviceaccount.com",
    echo "serviceAccount:service-${ml_p}@gcp-sa-aiplatform.iam.gserviceaccount.com",
    ```

1.  Many of the necessary service agents and permissions were deployed in all project environments for machine-learning.  Additional entries will be needed for each environment.

1. Add in more agents to the DEVELOPMENT.AUTO.TFVARS file under `egress_policies`.
Notably:

   * "serviceAccount:bq-[prj-d-bu3machine-learning-project-number]@bigquery-encryption.iam.gserviceaccount.com"

    This should be added under identities.  It should look like this::

    ```
    egress_policies = [
          // notebooks
          {
              "from" = {
              "identity_type" = ""
              "identities" = [
                  "serviceAccount:bq-[prj-d-bu3machine-learning-project-number]@bigquery-encryption.iam.gserviceaccount.com"   << New Addition
                  "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@gcp-sa-notebooks.iam.gserviceaccount.com",
                  "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@compute-system.iam.gserviceaccount.com",
              ]
              },
              "to" = {
              "resources" = ["projects/[prj-d-kms-project-number]"]
              "operations" = {
                  "compute.googleapis.com" = {
                  "methods" = ["*"]
                  }
                  "cloudkms.googleapis.com" = {
                  "methods" = ["*"]
                  }
              }
              }
          },
      ]
   ```

1. Remain in DEVELOPMENT.AUTO.TFVARS and include this entry under `egress_policies`.  Ensure you replace all [project numbers] with their corresponding project:

    ```
      // artifact Registry
      {
        "from" = {
          "identity_type" = ""
          "identities" = [
            "serviceAccount:service-[prj-d-bu3machine-learning-number]@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
          ]
        },
        "to" = {
          "resources" = ["projects/[prj-c-bu3artifacts-number]"]
          "operations" = {
            "artifactregistry.googleapis.com" = {
<<<<<<< HEAD
            "methods" = ["*"]
            }
            "cloudbuild.googleapis.com" = {
            "methods" = ["*"]
=======
              "methods" = ["*"]
>>>>>>> main
            }
          }
        }
      },
<<<<<<< HEAD
      {
      "from" = {
        "identity_type" = "ANY_IDENTITY"
        "identities"    = []
      },
      "to" = {
        "resources" = ["projects/[prj-d-bu3machine-learning-project-number]"]
        "operations" = {
          "aiplatform.googleapis.com" = {
          "methods" = ["*"]
          }
        }
        }
    },
=======
>>>>>>> main
      // Dataflow
      {
        "from" = {
          "identity_type" = ""
          "identities" = [
            "serviceAccount:service-[prj-n-bu3machine-learning-number]@dataflow-service-producer-prod.iam.gserviceaccount.com",
          ]
        },
        "to" = {
          "resources" = ["projects/[prj-n-bu3machine-learning-number]"]
          "operations" = {
            "compute.googleapis.com" = {
              "methods" = ["*"]
            }
          }
        }
      },
<<<<<<< HEAD
      {
        "from" = {
        "identity_type" = "ANY_IDENTITY"
        "identities"    = []
      },
        "to" = {
        "resources" = ["projects/[prj-d-kms-project-number]"]
        "operations" = {
            "cloudkms.googleapis.com" = {
            "methods" = ["*"]
          }
        }
        }
      },
      {
        "from" = {
        "identity_type" = ""
        "identities"    = ["serviceAccount:service-[prj-d-bu3machine-learning-project-number]@gcp-sa-aiplatform.iam.gserviceaccount.com"]
        },
        "to" = {
        "resources" = ["projects/[prj-d-bu3machine-learning-project-number]"]
        "operations" = {
            "storage.googleapis.com" = {
            "methods" = ["*"]
          }
        }
        }
    },
=======
>>>>>>> main
    ```

1. Under NON-PRODUCTION.AUTO.TFVARS, add these entries under `egress_policies`:

    ```
    {
      "from" = {
        "identity_type" = "ANY_IDENTITY"
        "identities"    = []
      },
      "to" = {
        "resources" = [
          "projects/[prj-c-bu3artifacts-number]"
        ]
        "operations" = {
          "artifactregistry.googleapis.com" = {
            "methods" = ["*"]
          }
        }
      }
    },
    // artifact Registry
    {
      "from" = {
        "identity_type" = ""
        "identities" = [
          "serviceAccount:service-[prj-n-bu3machine-learning-number]@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
        ]
      },
      "to" = {
        "resources" = ["projects/[prj-c-bu3artifacts-number]"]
        "operations" = {
          "artifactregistry.googleapis.com" = {
            "methods" = ["*"]
          }
        }
      }
    },
    // DataFlow
    {
      "from" = {
        "identity_type" = ""
        "identities" = [
          "serviceAccount:service-[prj-n-bu3machine-learning-number]@dataflow-service-producer-prod.iam.gserviceaccount.com",
        ]
      },
      "to" = {
        "resources" = ["projects/[prj-d-shared-restricted-number]"]
        "operations" = {
          "compute.googleapis.com" = {
            "methods" = ["*"]
          }
        }
      }
    },
    {
      "from" = {
        "identity_type" = ""
        "identities" = [
          "serviceAccount:[prj-n-bu3machine-learning-number]-compute@developer.gserviceaccount.com",
          "serviceAccount:service-[prj-d-bu3machine-learning-number]@gcp-sa-aiplatform.iam.gserviceaccount.com",
        ]
      },
      "to" = {
        "resources" = ["projects/[prj-p-bu3machine-learning-number]"]
        "operations" = {
          "aiplatform.googleapis.com" = {
            "methods" = ["*"]
          },
          "storage.googleapis.com" = {
            "methods" = ["*"]
          },
          "bigquery.googleapis.com" = {
            "methods" = ["*"]
          }
        }
      }
    },
    ```

1.  Under PRODUCTION.AUTO.TFVARS, add these entries under `egress_policies`:

    ```
    {
      "from" = {
        "identity_type" = ""
        "identities" = [
          "serviceAccount:service-[prj-p-bu3machine-learning-number]@gcp-sa-aiplatform.iam.gserviceaccount.com",
          "serviceAccount:service-[prj-p-bu3machine-learning-number]@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
          "serviceAccount:cloud-cicd-artifact-registry-copier@system.gserviceaccount.com",
        ]
      },
      "to" = {
        "resources" = [
          "projects/[prj-n-bu3machine-learning-number]",
          "projects/[prj-c-bu3artifacts-number]",
        ]
        "operations" = {
          "artifactregistry.googleapis.com" = {
            "methods" = ["*"]
          },
          "storage.googleapis.com" = {
            "methods" = ["*"]
          },
          "bigquery.googleapis.com" = {
            "methods" = ["*"]
          }
        }
      }
    },
    ```

### Service Catalog

Once you have set up service catalog and attempt to deploy out terraform code, there is a high chance you will encounter this error:
`Permission denied; please check you have the correct IAM permissions and APIs enabled.`
This is  due to a VPC Service control error that until now, is impossible to add into the egress policy.  Go to `prj-d-bu3machine-learning` project and view the logs, filtering for ERRORS.  There will be a VPC Service Controls entry that has an `egressViolation`.  It should look something like the following:
```
egressViolations: [
   0: {
      servicePerimeter: "accessPolicies/1066661933618/servicePerimeters/sp_d_shared_restricted_default_perimeter_f3fv"
      source: "projects/[machine-learning-project-number]"
      sourceType: "Resource"
      targetResource: "projects/[unknown-project-number]"
   }
]
```

we want the `unknown-project-number` here.  Add this into your `egress_policies` in `3-networks` under DEVELOPMENT.AUTO.TFVARS, NON-PRODUCTION.AUTO.TFVARS & PRODUCTION.AUTO.TFVARS

```
// Service Catalog
  {
    "from" = {
      "identity_type" = "ANY_IDENTITY"
      "identities"    = []
    },
    "to" = {
      "resources" = ["projects/[unknown-project-number]"]
      "operations" = {
        "cloudbuild.googleapis.com" = {
          "methods" = ["*"]
        }
      }
    }
  },
```

### Machine Learning Pipeline

This environment is set up for interactive coding and experimentations. After the project is up, the vertex workbench is deployed from service catalog and The datascientis can use it to write their code including any experiments, data processing code and pipeline components. In addition, a cloud storage bucket is deployed to use as the storage for our operations. Optionally a composer environment is which will later be used to schedule the pipeline run on intervals.

For our pipeline which trains and deploys a model on the [census income dataset](https://archive.ics.uci.edu/dataset/20/census+income), we use a notebook in the dev workbench to create our pipeline components, put them together into a pipeline and do a dry run of the pipeline to make sure there are no issues. You can access the repository [here](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/tree/main/7-vertexpipeline). [^1]

[^1]: There is a Dockerfile in the repo which is the docker image used to run all pipeline steps and cloud build steps. In non-prod and prod environments, the only NIST compliant way to access additional dependencies and requirements is via docker images uploaded to artifact registry. We have baked everything for running the pipeline into this docker which exsits in the shared artifact registry.

Once confident, we divide the code in two separate files to use in our CI/CD process in the non-prod environment. First is *compile_pipeline.py* which includes the code to build the pipeline and compile it into a directory (in our case, /common/vertex-ai-pipeline/pipeline_package.yaml)

The second file, i.e. *runpipeline.py* includes the code for running the compiled pipeline. This is where the correct environemnt variables for non-prod nad prod (e.g., service accounts to use for each stage of the pipeline, kms keys corresponding to each step, buckets, etc.) are set. And eventually the pipeline is loaded from the yaml file at *common/vertex-ai-pipeline/pipeline_package.yaml* and submitted to vertex ai.


There is a *cloudbuild.yaml* file in the repo with the CI/CD steps as follows:

1. Upload the Dataflow src file to the bucket in non-prod
2. Upload the dataset to the bucket
3. Run *compile_pipeline.py* to compile the pipeline
4. Run the pipeline via *runpipeline.py*
5. Optionally, upload the pipeline's yaml file to the composer bucket to make it available for scheduled pipeline runs

The cloud build trigger will be setup in the non-prod project which is where the ML pipeline will run. There are currently three branches on the repo namely dev, staging (non-prod), and prod. Cloud build will trigger the pipeline once there is a merge into the staging (non-prod) branch from dev. However, model deployment and monitorings steps take place in the prod environment. As a result, the service agents and service accounts of the non-prod environment are given some permission on the prod environment and vice versa.

Each time a pipeline job finishes successfully, a new version of the census income bracket predictor model will be deployed on the endpoint which will only take 25 percent of the traffic wherease the other 75 percent goes to the previous version of the model to enable A/B testing.

You can read more about the details of the pipeline components on the [pipeline's repo](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/tree/main/7-vertexpipeline#readme)

### Step by step

Before you start, make sure you have your personal git access token ready. The git menu option on the left bar of the workbench requires the personal token to connect to git and clone the repo.
Also make sure to have a gcs bucket ready to store the artifacts for the tutorial. To deploy the bucket, you can go to service catalog and create a new deployment from the storage bucket solution.

<<<<<<< HEAD
Additionally, the following Service Accounts need to be created with the respective roles since the Compute Engine SA cannot to be used to deploy the Dataflow and Vertex Pipeline steps:

`dataflow_runner_sa@prj-d-bu3machine-learning-[project-number].iam.gserviceaccount.com`

This service account requires the following roles:
* `roles/bigquery.admin`
* `roles/dataflow.admin`
* `roles/dataflow.worker`
* `roles/storage.admin`


`vertex_model_sa@prj-d-bu3machine-learning-[project-number].iam.gserviceaccount.com`

No role is required for the `vertex_model_sa`.

Run the command below to grant the notebook to be able to create jobs in BigQuery:
```
bq query --nouse_legacy_sql \
'ALTER PROJECT `prj-d-bu3machine-learning-[project-number]` SET OPTIONS \
(`region-us-central1.default_kms_key_name`="projects/[prj-d-kms-project-ID]/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-d-bu3machine-learning");'
```


#### 1. Run the notebook

- Take assets/Vertexpipeline folder and make you own copy as a standalone git repository and clone it in the workbench in your dev project. Create a dev branch of the new repository. Switch to the dev branch by choosing it in the branch section of the git view. Now go back to the file browser view by clicking the first option on the left bar menu. Navigate to the directory you just clone and run [the notebook](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/blob/main/examples/machine-learning-pipeline/assets/Vertexpipeline/census_pipeline.ipynb) cell by cell. Pay attention to the instructions and comments in the notebook and don't forget to set the correct values corresponding to your dev project.
=======
#### 1. Run the notebook

- Take 7-vertexpipeline folder and make you own copy as a standalone git repository and clone it in the workbench in your dev project. Create a dev branch of the new repository. Switch to the dev branch by choosing it in the branch section of the git view. Now go back to the file browser view by clicking the first option on the left bar menu. Navigate to the directory you just clone and run [the notebook](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/blob/main/7-vertexpipeline/census_pipeline.ipynb) cell by cell. Pay attention to the instructions and comments in the notebook and don't forget to set the correct values corresponding to your dev project.
>>>>>>> main

#### 2. Configure cloud build

- After the notebook runs successfully and the pipeline's test run finishes in the dev environment, create a cloud build trigger in your non-prod project. Configure the trigger to run when there is a merge into the staging (non-prod) branch by following the below settings.

    |Setting|Value|
    |-------|-----|
    |Event|push to branch|
    |Repository generation|1st gen|
    |Repository|the url to your fork of the repo|
    |Branch|staging|
    |Configuration|Autodetected/Cloud Build configuration file (yaml or json)|
    |Location|Repository|
    |Cloud Build configuration file location|cloudbuild.yaml|


- Open the cloudbuild.yaml file in your workbench and for steps 1 which uploads the source code for the dataflow job to your bucket.

    ```
    name: 'gcr.io/cloud-builders/gsutil'
    args: ['cp', '-r', './src', 'gs://{your-bucket-name}']
    ```

- Similarly in step 2, replace the bucket name with the name of your own bucket in the non-prod project in order to upload the data to your bucket:
    ```
    name: 'gcr.io/cloud-builders/gsutil'
    args: ['cp', '-r', './data', 'gs://{your-bucket-name}']
    ```

- Change the name of the image for step 3 and 4 to that of your own artifact project, i.e., `us-central1-docker.pkg.dev/{artifact_project_id}/c-publish-artifacts/vertexpipeline:v2` This is the project with artifact registry that houses the image required to run the pipeline.

```
 - name: 'us-central1-docker.pkg.dev/{your-artifact-project}/c-publish-artifacts/vertexpipeline:v2'
    entrypoint: 'python'
    args: ['compile_pipeline.py']
    id: 'compile_job'

  # run pipeline
  - name: 'us-central1-docker.pkg.dev/{your-artifact-project}/c-publish-artifacts/vertexpipeline:v2'
    entrypoint: 'python'
    args: ['runpipeline.py']
    id: 'run_job'
    waitFor: ['compile_job']
```

- Optionally, if you want to schedule pipeline runs on regular intervals, uncomment the last two steps and replace the composer bucket with the name of your composer's bucket. The first step uploads the pipeline's yaml to the bucket and the second step uploads the dag to read that yaml and trigger the vertex pipeline:
```
 # upload to composer
   - name: 'gcr.io/cloud-builders/gsutil'
     args: ['cp', './common/vertex-ai-pipeline/pipeline_package.yaml', 'gs://{your-composer-bucket}/dags/common/vertex-ai-pipeline/']
     id: 'upload_composer_file'

 # upload pipeline dag to composer
    - name: 'gcr.io/cloud-builders/gsutil'
      args: ['cp', './composer/dags/dag.py', 'gs://{your-composer-bucket}/dags/']
      id: 'upload dag'
```

#### 3. Configure variables in compile_pipeline.py and runpipeline.py

- Make sure to set the correct values for variables like **PROJECT_ID**, **BUCKET_URI**, encryption keys and service accounts, etc.:

    |variable|definition|example value|How to obtain|
    |--------|----------|-------------|-------------|
    |PROJECT_ID|The id of the non-prod project|`{none-prod-project-id}`|From the project's menu in console navigate to the `fldr-non-production/fldr-non-production-bu3` folder; here you can find the machine learning project in non-prod (`prj-n-bu3machine-learning`) and obtain its' ID|
    |BUCKET_URI|URI of the non-prod bucket|`gs://non-prod-bucket`|From the project menu in console navigate to the non-prod ML project `fldr-non-production/fldr-non-production-bu3/prj-n-bu3machine-learning` project, navigate to cloud storage and copy the name of the bucket available there|
    |REGION|The region for pipeline jobs|Can be left as default `us-central1`|
    |PROD_PROJECT_ID|ID of the prod project|`prod-project-id`|In console's project menu, navigate to the `fldr-production/fldr-production-bu3` folder; here you can find the machine learning project in prod (`prj-p-bu3machine-learning`) and obtain its' ID|
    |Image|The image artifact used to run the pipeline components. The image is already built and pushed to the artifact repository in your artifact project under the common folder|`f"us-central1-docker.pkg.dev/{{artifact-project}}/{{artifact-repository}}/vertexpipeline:v2"`|Navigate to `fldr-common/prj-c-bu3artifacts` project. Navigate to the artifact registry repositories in the project to find the full name of the image artifact.|
    |DATAFLOW_SUBNET|The shared subnet in non-prod env required to run the dataflow job|`https://www.googleapis.com/compute/v1/projects/{non-prod-network-project}/regions/us-central1/subnetworks/{subnetwork-name}`|Navigate to the `fldr-network/prj-n-shared-restricted` project. Navigate to the VPC networks and under the subnets tab, find the name of the network associated with your region (us-central1)|
    |SERVICE_ACCOUNT|The service account used to run the pipeline and it's components such as the model monitoring job. This is the compute default service account of non-prod if you don't plan on using another costume service account|`{non-prod-project_number}-compute@developer.gserviceaccount.com`|Head over to the IAM page in the non-prod project `fldr-non-production/fldr-non-production-bu3/prj-n-bu3machine-learning`, check the box for `Include Google-provided role grants` and look for the service account with the `{project_number}-compute@developer.gserviceaccount.com`|
    |PROD_SERICE_ACCOUNT|The service account used to create endpoint, upload the model, and deploy the model in the prod project. This is the compute default service account of prod if you don't plan on using another costume service account|`{prod-project_number}-compute@developer.gserviceaccount.com`|Head over to the IAM page in the prod project `fldr-production/fldr-production-bu3/prj-p-bu3machine-learning`, check the box for `Include Google-provided role grants` and look for the service account with the `{project_number}-compute@developer.gserviceaccount.com`|
    |deployment_config['encryption']|The kms key for the prod env. This key is used to encrypt the vertex model, endpoint, model deployment, and model monitoring.|`projects/{prod-kms-project}/locations/us-central1/keyRings/{keyring-name}/cryptoKeys/{key-name}`|Navigate to `fldr-production/prj-n-kms`, navigate to the Security/Key management in that project to find the key in `sample-keyring` keyring of your target region `us-central1`|
    |encryption_spec_key_name|The name of the encryption key for the non-prod env. This key is used to create the vertex pipeline job and it's associated metadata store|`projects/{non-prod-kms-project}/locations/us-central1/keyRings/{keyring-name}/cryptoKeys/{key-name}`|Navigate to `fldr-non-production/prj-n-kms`, navigate to the Security/Key management in that project to find the key in `sample-keyring` keyring of your target region `us-central1`|
    |monitoring_config['email']|The email that Vertex AI monitoring will email alerts to|`your email`|your email associated with your gcp account|

The compile_pipeline.py and runpipeline.py files are commented to point out these variables.

#### 4. Merge and deploy

- Once everything is configured, you can commit your changes and push to the dev branch. Then, create a PR to from dev to staging(non-prod) which will result in triggering the pipeline if approved. The vertex pipeline takes about 30 minutes to finish and if there are no errors, a trained model will be deployed to and endpoint in the prod project which you can use to make prediction requests.

### 5. Model Validation

Once you have the model running at an endpoint in the production project, you will be able to test it.
Here are step-by-step instructions to make a request to your model using `gcloud` and `curl`:

1. Initialize variables on your terminal session

    ```bash
    ENDPOINT_ID=<REPLACE_WITH_ENDPOINT_ID>
    PROJECT_ID=<REPLACE_WITH_PROJECT_ID>
    INPUT_DATA_FILE="body.json"
    ```

    > You can retrieve your ENDPOINT_ID by running `gcloud ai endpoints list --region=us-central1 --project=<PROD_ML_PROJECT>` or by navigating to it on the Google Cloud Console (https://console.cloud.google.com/vertex-ai/online-prediction/endpoints?project=<PROD_ML_PROJECT>`)

2. Create a file named `body.json` and put some sample data into it:

    ```json
    {
        "instances": [
            {
                "features/gender": "Female",
                "features/workclass": "Private",
                "features/occupation": "Tech-support",
                "features/marital_status": "Married-civ-spouse",
                "features/race": "White",
                "features/capital_gain": 0,
                "features/education": "9th",
                "features/age": 33,
                "features/hours_per_week": 40,
                "features/relationship": "Wife",
                "features/native_country": "Canada",
                "features/capital_loss": 0
            }
        ]
    }
    ```

3. Run a curl request using `body.json` file as the JSON Body.

    ```bash
    curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    https://us-central1-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/endpoints/${ENDPOINT_ID}:predict -d "@${INPUT_DATA_FILE}"
    ```

    - You should get an output from 0 to 1, indicating the level of confidence of the binary classification based on the parameters above.
    Values closer to 1 means the individual is more likely to be included in the income_bracket greater than 50K.

#### Common errors

- ***google.api_core.exceptions.ResourceExhausted: 429 The following quotas are exceeded: ```CustomModelServingCPUsPerProjectPerRegion 8: The following quotas are exceeded: CustomModelServingCPUsPerProjectPerRegion``` or similar error***:
<<<<<<< HEAD
This is likely due to the fact that you have too many models uploaded and deployed in Vertex AI. To resolve the issue, you can either submit a quota increase request or undeploy and delete a few models to free up resources.

- ***Google Compute Engine Metadata service not available/found***:
You might encounter this when the vertex pipeline job attempts to run even though it is an obsolete issue according to [this thread](https://issuetracker.google.com/issues/229537245#comment9). It'll most likely resolve by re-running the vertex pipeline.
=======
This is likely due to the fact that you have too many models uploaded and deployed in Vertex AI. To resolve the issue, you can either submit a quota increase request or undeploy and delete a few models to free up resources

- ***Google Compute Engine Metadata service not available/found***:
You might encounter this when the vertex pipeline job attempts to run even though it is an obsolete issue according to [this thread](https://issuetracker.google.com/issues/229537245#comment9). It'll most likely resolve by re-running the vertex pipeline
>>>>>>> main
