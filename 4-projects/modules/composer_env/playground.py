
sa_accounts = [
    "sa1",
    "sa2",
    "sa3",
  ]

service_catalog_crypto_key = {
    "projects/prj-d-kms-cgvl/locations/us-central1/keyRings/sample-keyring": {
        "destroy_scheduled_duration": "86400s",
        "id": "projects/prj-d-kms-cgvl/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-d-bu3cmpsr-pipeln",
        "import_only": False,
        "key_ring": "projects/prj-d-kms-cgvl/locations/us-central1/keyRings/sample-keyring",
        "labels": {},
        "name": "prj-d-bu3cmpsr-pipeln",
        "purpose": "ENCRYPT_DECRYPT",
        "rotation_period": "7776000s",
        "skip_initial_version_creation": False,
        "timeouts": None,  # Assuming this is equivalent to null in Terraform
        "version_template": [
            {
                "algorithm": "GOOGLE_SYMMETRIC_ENCRYPTION",
                "protection_level": "SOFTWARE"
            }
        ]
    },
    "projects/prj-d-kms-cgvl/locations/us-east4/keyRings/sample-keyring": {
        "destroy_scheduled_duration": "86400s",
        "id": "projects/prj-d-kms-cgvl/locations/us-east4/keyRings/sample-keyring/cryptoKeys/prj-d-bu3cmpsr-pipeln",
        "import_only": False,
        "key_ring": "projects/prj-d-kms-cgvl/locations/us-east4/keyRings/sample-keyring",
        "labels": {},
        "name": "prj-d-bu3cmpsr-pipeln",
        "purpose": "ENCRYPT_DECRYPT",
        "rotation_period": "7776000s",
        "skip_initial_version_creation": False,
        "timeouts": None,  # Assuming this is equivalent to null in Terraform
        "version_template": [
            {
                "algorithm": "GOOGLE_SYMMETRIC_ENCRYPTION",
                "protection_level": "SOFTWARE"
            }
        ]
    }
}

result_list = []

for key, value in service_catalog_crypto_key.items():
    for sa in sa_accounts:
        result_list.append({"id": value["id"], "sa_account": sa})

# Print the result list
print(result_list)