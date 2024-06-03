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
<td>5-app-infra  6-machine-learning(this file)</td>
<td>Deploys modules based on the modules created in 3-service-catalog</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-google-enterprise-genai README](https://github.com/terraform-google-modules/terraform-google-enterprise-genai)
file.

## Purpose

## Prerequisites

1. 0-bootstrap executed successfully.
1. 1-org executed successfully.
1. 2-environments executed successfully.
1. 3-networks executed successfully.
1. 4-projects executed successfully.
1. 5-app-infra executed successfully.

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

   cp -RT ../terraform-google-enterprise-genai/6-machine-learning/ .
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

1. cd out of this directory before continuting over to `7-machine-learning-post-deployment`

   ```bash
   cd ..
   ```

## Running Terraform locally

1. The next instructions assume that you are at the same level of the `terraform-google-enterprise-genai` folder. Change into `6-machine-learning` folder, copy the Terraform wrapper script and ensure it can be executed.

   ```bash
   cd terraform-google-enterprise-genai/6-machine-learning
   cp ../build/tf-wrapper.sh .
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

   terraform_sa=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-machine-learning"' --raw-output)
   echo ${terraform_sa}

   gcloud iam service-accounts add-iam-policy-binding ${terraform_sa} --project ${project_id} --member="${member}" --role="roles/iam.serviceAccountTokenCreator"
   ```

1. Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json state_buckets | jq '."bu3-machine-learning"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

1. Update `modules/base_env/main.tf` with Service Catalog Project Id.

   ```bash
   export service_catalog_project_id=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -raw service_catalog_project_id)
   echo "service_catalog_project_id = ${service_catalog_project_id}"

   ## Linux
   sed -i "s/SERVICE_CATALOG_PROJECT_ID/${service_catalog_project_id}/g" ./modules/base_env/main.tf
   ```

We will now deploy each of our environments (development/production/non-production) using this script.
When using Cloud Build or Jenkins as your CI/CD tool, each environment corresponds to a branch in the repository for the `6-machine-learning` step. Only the corresponding environment is applied.

To use the `validate` option of the `tf-wrapper.sh` script, please follow the [instructions](https://cloud.google.com/docs/terraform/policy-validation/validate-policies#install) to install the terraform-tools component.

1. Use `terraform output` to get the Infra Pipeline Project ID from 4-projects output.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../4-projects/business_unit_3/shared/" output -json terraform_service_accounts | jq '."bu3-machine-learning"' --raw-output)
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
              "methods" = ["*"]
            }
          }
        }
      },
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

## SERVICE CATALOG

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
