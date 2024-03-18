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

1. Add in more agents to the  DEVELOPMENT.AUTO.TFVARS file under `egress_policies`. 
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
