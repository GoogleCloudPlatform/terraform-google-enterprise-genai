ingress_policies = [
  // users
  {
    "from" = {
      "identity_type" = "ANY_IDENTITY"
      "sources" = {
        "access_level" = "accessPolicies/270868347751/accessLevels/alp_n_shared_restricted_members_b174"
      }
    },
    "to" = {
      "resources" = [
        "projects/677782245477", // prj-n-shared-restricted-f8gm
        "projects/116967579077", // prj-n-kms-en5b
        "projects/800630573119", // prj-n-bu3machine-learning-nksb
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
]
