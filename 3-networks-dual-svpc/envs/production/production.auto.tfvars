ingress_policies = [
  // users
  {
    "from" = {
      "identity_type" = "ANY_IDENTITY"
      "sources" = {
        "access_level" = "accessPolicies/270868347751/accessLevels/alp_p_shared_restricted_members_12ff"
      }
    },
    "to" = {
      "resources" = [
        "projects/717936582660",  // prj-p-bu3machine-learning-6s5x
        "projects/1068180808710", // prj-p-kms-wlv8
        "projects/531523829881",  // prj-p-shared-restricted-yjap
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
