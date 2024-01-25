ingress_policies = [
  // users
  {
    "from" = {
      "identity_type" = "ANY_IDENTITY"
      "sources" = {
        "access_level" = "accessPolicies/270868347751/accessLevels/alp_d_shared_restricted_members_556e"
      }
    },
    "to" = {
      "resources" = [
        "projects/986471410663", // prj-d-shared-restricted-iibs
        "projects/126209299992", // prj-d-kms-cgvl
        "projects/234217653834", // prj-d-bu3machine-learning
      ]
      "operations" = {
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
      }
    }
  },
]

egress_policies = [
  // notebooks
  {
    "from" = {
      "identity_type" = ""
      "identities" = [
        "serviceAccount:service-166130363197@gs-project-accounts.iam.gserviceaccount.com", // Artifact Registry - probably Google project
        "serviceAccount:service-590555654900@compute-system.iam.gserviceaccount.com",      // Cloud Composer SA (GKE) for KMS access
        "serviceAccount:service-88191347087@compute-system.iam.gserviceaccount.com",       // Cloud Composer SA (GKE) for KMS access
        "serviceAccount:bq-234217653834@bigquery-encryption.iam.gserviceaccount.com",      // BigQuery SA for KMS access in the Machine Learning Project
        "serviceAccount:service-234217653834@gcp-sa-notebooks.iam.gserviceaccount.com",    // Notebooks SA for Notebooks in Machine Learning Project
        "serviceAccount:service-234217653834@compute-system.iam.gserviceaccount.com",      // Compute SA for Notebooks Instance in Machine Learning Project
      ]
    },
    "to" = {
      "resources" = ["projects/126209299992"] // prj-d-kms-cgvl
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
  // bucket  // Mark for deletion
  {
    "from" = {
      "identity_type" = ""
      "identities" = [
        "user:adam.hussein@badal.io",
        "user:kevin.cheema@badal.io",
        "user:majid.alikhani@badal.io",
        "user:mike.futerko@badal.io",
        "user:renato.dattilo@badal.io",
        "user:zbutt@badal.io",
      ]
    },
    "to" = {
      "resources" = ["projects/926101806329"] // prj-c-logging-va6h
      "operations" = {
        "storage.googleapis.com" = {
          "methods" = ["*"]
        }
      }
    }
  },
  // Service Catalog
  {
    "from" = {
      "identity_type" = "ANY_IDENTITY"
      "identities"    = []
    },
    "to" = {
      "resources" = ["projects/586809574927"] // google project (deals with composer/k8s)
      "operations" = {
        "cloudbuild.googleapis.com" = {
          "methods" = ["*"]
        }
      }
    }
  },
]
