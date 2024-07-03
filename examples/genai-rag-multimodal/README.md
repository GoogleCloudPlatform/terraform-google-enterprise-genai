# Multimodal RAG Langchain Example

## Overview

Retrieval Augmented Generation (RAG) has become a popular paradigm for enabling LLMs to access external data and also as a mechanism for [Grounding](https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/overview), to mitigate against hallucinations.

In this notebook, you will perform multimodal RAG by performing Q&A over a financial document filled with both text and images.

This example is an adapted version of the sample Generative AI notebook from the Google Cloud codebase. You can find the original example and other notebooks in the [Google Cloud Platform Generative AI](https://github.com/GoogleCloudPlatform/generative-ai/tree/main) repository.

The main modifications to the original example include:

- Adaptations to comply with Cloud Foundation Toolkit security measures.
- Installation of additional libraries in the Conda environment.
- Use of Vertex AI Workbench to run the notebook with a custom Service Account.
- Implementation of Vector Search on Vertex AI with [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect).

## Requirements

- Terraform v1.7.5
- [Authenticated Google Cloud SDK 469.0.0](https://cloud.google.com/sdk/docs/authorizing)

### Terraform Variables Configuration

- Update the `terraform.tfvars` file with values from your environment.

  ```terraform
  kms_key                   = "projects/KMS-PROJECT-ID/locations/REGION/keyRings/ML-ENV-KEYRING/cryptoKeys/ML-ENV-KEY"
  network                   = "projects/NETWORK-PROJECT-ID/global/networks/NETWORK-NAME"
  subnet                    = "projects/NETWORK-PROJECT-ID/regions/REGION/subnetworks/SUBNET-NAME"
  machine_learning_project  = "MACHINE-LEARNING-PROJECT-ID"
  vector_search_vpc_project = "NETWORK-PROJECT-ID"
  ```

- Assuming you are deploying the example on top of the development environment, the following instructions will provide you more insight on how to retrieve these values:
  - **NETWORK-PROJECT-ID**: Run `terraform output -raw restricted_host_project_id` on `gcp-networks` repository, inside the development environment directory and branch.
  - **NETWORK-NAME**: Run `terraform output -raw restricted_network_name` on `gcp-networks` repository, inside the development environment directory and branch.
  - **MACHINE-LEARNING-PROJECT-ID**: Run `terraform output -raw machine_learning_project_id` on `gcp-projects` repository, inside the Machine Learning business unit directory and on the development branch.
  - **KMS-PROJECT-ID**, **ML-ENV-KEYRING**, **ML-ENV-KEY**: Run `terraform output machine_learning_kms_keys` on `gcp-projects` repository, inside the Machine Learning business unit directory and on the development branch.
  - **REGION**: The chosen region.

## Deploying infrastructure using Machine Learning Infra Pipeline

### Required Permissions and VPC-SC adjustments for pipeline Service Account

- The Service Account that runs the Pipeline must have `roles/compute.networkUser` on the Shared VPC Host Project, you can give this role by running the command below:

  ```bash
  SERVICE_ACCOUNT=$(terraform -chdir="./gcp-projects/ml_business_unit/shared" output -json terraform_service_accounts | jq -r '."ml-machine-learning"')

  gcloud projects add-iam-policy-binding <INSERT_HOST_VPC_NETWORK_PROJECT_HERE> --member="serviceAccount:$SERVICE_ACCOUNT" --role="roles/compute.networkUser"
  ```

- Add the build service account in the development VPC-SC perimeter. You can do this by adding "serviceAccount:<INSERT_SERVICE_ACCOUNT_EMAIL_HERE>" to `perimeter_additional_members` in `common.auto.tfvars` (development branch). If the command above executed succesfully, you can run `echo $SERVICE_ACCOUNT` to retrieve the Pipeline Service Account e-mail.

### Deployment steps

**IMPORTANT:** Please note that the steps below are assuming you are checked out on the same level as `terraform-google-enterprise-genai/` and the other repos (`gcp-bootstrap`, `gcp-org`, `gcp-projects`...).

- Retrieve the Project ID where the Machine Learning Pipeline Repository is located in.

  ```bash
  export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
  echo ${INFRA_PIPELINE_PROJECT_ID}
  ```

- Clone the repository.

  ```bash
  gcloud source repos clone ml-machine-learning --project=${INFRA_PIPELINE_PROJECT_ID}
  ```

- Navigate into the repo and the desired branch. Create directories if they don't exist.

  ```bash
  cd ml-machine-learning
  git checkout -b development

  mkdir -p ml_business_unit/development
  mkdir -p modules
  ```

- Copy required files to the repository.

  ```bash
  cp -R ../terraform-google-enterprise-genai/examples/genai-rag-multimodal ./modules
  cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
  cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
  chmod 755 ./tf-wrapper.sh

  cat ../terraform-google-enterprise-genai/examples/genai-rag-multimodal/terraform.tfvars >> ml_business_unit/development/genai_example.auto.tfvars
  cat ../terraform-google-enterprise-genai/examples/genai-rag-multimodal/variables.tf >> ml_business_unit/development/variables.tf
  ```

  > NOTE: Make sure there are no variable name collision for variables under `terraform-google-enterprise-genaiexamples/genai-rag-multimodal/variables.tf` and that your `terraform.tfvars` is updated with values from your environment.

- Validate that variables under `ml_business_unit/development/genai_example.auto.tfvars` are correct.

  ```bash
  cat ml_business_unit/development/genai_example.auto.tfvars
  ```

- Create a file named `genai_example.tf` under `ml_business_unit/development` path that calls the module.

  ```terraform
  module "genai_example" {
    source = "../../modules/genai-rag-multimodal"

    kms_key                   = var.kms_key
    network                   = var.network
    subnet                    = var.subnet
    machine_learning_project  = var.machine_learning_project
    vector_search_vpc_project = var.vector_search_vpc_project
  }
  ```

- Verify if `backend.tf` file exists at `ml-machine-learning/ml_business_unit/development`.
  - If there is a `backend.tf` file, proceed with the next step and ignore the sub-steps below.
  - If there is no `backend.tf` file, follow the sub-steps below:
    - Create the file and put the following content into it:

      ```terraform
      terraform {
        backend "gcs" {
          bucket = "UPDATE_APP_INFRA_BUCKET"
          prefix = "terraform/app-infra/ml_business_unit/development"
        }
      }
      ```

    - Run the command below to update `UPDATE_APP_INFRA_BUCKET`:

      ```bash
      export backend_bucket=$(terraform -chdir="../gcp-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-artifact-publish"' --raw-output)
      echo "backend_bucket = ${backend_bucket}"

      for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
      ```

- Commit and push

  ```terraform
  git add .
  git commit -m "Add GenAI example"

  git push origin development
  ```

## Deploying infrastructure using terraform locally

- Run `terraform init` inside this directory.
- Run `terraform apply` inside this directory.

## Post-Deployment

### Allow file download from Google Notebook Examples Bucket on VPC-SC Perimeter

When running the Notebook, you will reach a step that downloads an example PDF file from a bucket, you need to add the egress rule below on the VPC-SC perimeter to allow the operation. You can do this by adding this rule to `egress_rule` variable on `gcp-networks/envs/development/development.auto.tfvars` on the development branch.

```terraform
{
  "from" = {
    "identity_type" = ""
    "identities" = [
      "serviceAccount:rag-notebook-runner@<INSERT_YOUR_MACHINE_LEARNING_PROJECT_ID_HERE>.iam.gserviceaccount.com"
    ]
  },
  "to" = {
    "resources" = ["projects/200612033880"]  # Google Cloud Example Project
    "operations" = {
        "storage.googleapis.com" = {
        "methods" = [
            "google.storage.buckets.list",
            "google.storage.buckets.get",
            "google.storage.objects.get",
            "google.storage.objects.list",
          ]
        }
    }
  }
},
```

## Usage

Once all the requirements are set up, you can start by running and adjusting the notebook step-by-step.

To run the notebook, open the Google Cloud Console on Vertex AI Workbench (`https://console.cloud.google.com/vertex-ai/workbench/instances?referrer=search&project=<MACHINE_LEARNING_PROJECT_ID>`), click open JupyterLab on the created instance and upload the notebook (`multimodal_rag_langchain.ipynb`) in this repo to it.

### Optional: Use `terraform output` and bash command to fill in fields in the notebook

#### Infra Pipeline (Cloud Build)

If you ran using Cloud Build, proceed with the steps below to use `terraform output`.

- Update `outputs.tf` file on `ml-machine-learning/ml_business_unit/development` with the following values:

  ```terraform
  output "private_endpoint_ip_address" {
    value       = module.genai_example.private_endpoint_ip_address
  }

  output "host_vpc_project_id" {
    value       = module.genai_example.host_vpc_project_id
  }

  output "host_vpc_network" {
    value       = module.genai_example.host_vpc_network
  }

  output "notebook_project_id" {
    value       = module.genai_example.notebook_project_id
  }

  output "vector_search_bucket_name" {
    value       = module.genai_example.vector_search_bucket_name
  }
  ```

- Run `./tf-wrapper init development` on `ml-machine-learning`.

- Extract values from `terraform output` and validate. You must run the commands below at `ml-machine-learning/ml_business_unit/development`.

  ```bash
  export private_endpoint_ip_address=$(terraform output -raw private_endpoint_ip_address)
  echo private_endpoint_ip_address=$private_endpoint_ip_address

  export host_vpc_project_id=$(terraform output -raw host_vpc_project_id)
  echo host_vpc_project_id=$host_vpc_project_id

  export notebook_project_id=$(terraform output -raw notebook_project_id)
  echo notebook_project_id=$notebook_project_id

  export vector_search_bucket_name=$(terraform output -raw vector_search_bucket_name)
  echo vector_search_bucket_name=$vector_search_bucket_name

  export host_vpc_network=$(terraform output -raw host_vpc_network)
  echo host_vpc_network=$host_vpc_network
  ```

- Search and Replace using `sed` command.

  ```bash
  sed -i "s/<INSERT_PRIVATE_IP_VALUE_HERE>/$private_endpoint_ip_address/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_HOST_VPC_PROJECT_ID>/$host_vpc_project_id/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_NOTEBOOK_PROJECT_ID>/$notebook_project_id/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_BUCKET_NAME>/$vector_search_bucket_name/g" multimodal_rag_langchain.ipynb

  sed -i "s:<INSERT_HOST_VPC_NETWORK>:$host_vpc_network:g" multimodal_rag_langchain.ipynb
  ```

#### Terraform Locally

If you ran terraform locally, proceed with the steps below to use `terraform output`.

You can save some time adjusting the notebook by running the commands below:

- Extract values from `terraform output` and validate.

  ```bash
  export private_endpoint_ip_address=$(terraform output -raw private_endpoint_ip_address)
  echo private_endpoint_ip_address=$private_endpoint_ip_address

  export host_vpc_project_id=$(terraform output -raw host_vpc_project_id)
  echo host_vpc_project_id=$host_vpc_project_id

  export notebook_project_id=$(terraform output -raw notebook_project_id)
  echo notebook_project_id=$notebook_project_id

  export vector_search_bucket_name=$(terraform output -raw vector_search_bucket_name)
  echo vector_search_bucket_name=$vector_search_bucket_name

  export host_vpc_network=$(terraform output -raw host_vpc_network)
  echo host_vpc_network=$host_vpc_network
  ```

- Search and Replace using `sed` command.

  ```bash
  sed -i "s/<INSERT_PRIVATE_IP_VALUE_HERE>/$private_endpoint_ip_address/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_HOST_VPC_PROJECT_ID>/$host_vpc_project_id/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_NOTEBOOK_PROJECT_ID>/$notebook_project_id/g" multimodal_rag_langchain.ipynb

  sed -i "s/<INSERT_BUCKET_NAME>/$vector_search_bucket_name/g" multimodal_rag_langchain.ipynb

  sed -i "s:<INSERT_HOST_VPC_NETWORK>:$host_vpc_network:g" multimodal_rag_langchain.ipynb
  ```

## Known Issues

- `Error: Error creating Instance: googleapi: Error 400: value_to_check(https://compute.googleapis.com/compute/v1/projects/...) is not found`.
  - When creating the VertexAI Workbench Instance through terraform you might face this issue. The issue is being tracked on this [link](https://github.com/hashicorp/terraform-provider-google/issues/17904).
  - If you face this issue you will not be able to use terraform to create the instance, therefore, you will need to manually create it on [Google Cloud Console](https://console.cloud.google.com/vertex-ai/workbench/instances) using the same parameters.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance\_location | Vertex Workbench Instance Location | `string` | `"us-central1-a"` | no |
| kms\_key | The KMS key to use for disk encryption | `string` | n/a | yes |
| machine\_learning\_project | Machine Learning Project ID | `string` | n/a | yes |
| machine\_name | The name of the machine instance | `string` | `"rag-notebook-instance"` | no |
| machine\_type | The type of machine to use for the instance | `string` | `"e2-standard-2"` | no |
| network | The Host VPC network ID to connect the instance to | `string` | n/a | yes |
| service\_account\_name | The name of the service account | `string` | `"rag-notebook-runner"` | no |
| subnet | The subnet ID within the Host VPC network to use in Vertex Workbench and Private Service Connect | `string` | n/a | yes |
| vector\_search\_address\_name | The name of the address to create | `string` | `"vector-search-endpoint"` | no |
| vector\_search\_bucket\_location | Bucket Region | `string` | `"US-CENTRAL1"` | no |
| vector\_search\_ip\_region | The region to create the address in | `string` | `"us-central1"` | no |
| vector\_search\_vpc\_project | The project ID where the Host VPC network is located | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| host\_vpc\_network | This is the Self-link of the Host VPC network |
| host\_vpc\_project\_id | This is the Project ID where the Host VPC network is located |
| notebook\_project\_id | The Project ID where the notebook will be run on |
| private\_endpoint\_ip\_address | The private IP address of the vector search endpoint |
| vector\_search\_bucket\_name | The name of the bucket that Vector Search will use |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
