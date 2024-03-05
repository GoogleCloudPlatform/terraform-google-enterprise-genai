## Post Deployment

Since the `machine-learning` project is in a service perimiter, there will be _additional_ entries that will be needed.  This is most notable for the `interactive` environment (development).  Since many of the necessary service agents and permissions were deployed in this project, we will _need to return to `3-networks`_ and add in more agents to the  DEVELOPMENT.AUTO.TFVARS file under `egress_policies`. 
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

## SERVICE CATALOG
Once you have set up service catalog and attempt to deploy out terraform code, there is a high chance you will encounter this error:
`Permission denied; please check you have the correct IAM permissions and APIs enabled.`
This is  due to a VPC Service control error that until now, is impossible to add into the egress policy.  Go to `prj-d-bu3machine-learning` project and view the logs.  There will be a VPC Service Controls entry that has an `egressViolation`.  It should look something like the following:
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
we want the `unknown-project-number` here.  Add this into your `egress_policies` in `3-networks` under DEVELOPMENT.AUTO.TFVARS 
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
