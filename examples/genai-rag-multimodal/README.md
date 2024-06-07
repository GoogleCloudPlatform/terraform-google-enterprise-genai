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

### Provision Infrastructure with Terraform

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

### Allow file download from Google Notebook Examples Bucket on VPC-SC Perimeter

When running the Notebook, you will reach a step that downloads an example PDF file from a bucket, you need to add the egress rule below on the VPC-SC perimeter to allow the operation.

```yaml
- egressFrom:
    identities:
    - serviceAccount:rag-notebook-runner@<INSERT_YOUR_MACHINE_LEARNING_PROJECT_ID_HERE>.iam.gserviceaccount.com
  egressTo:
      operations:
      - methodSelectors:
      - method: google.storage.buckets.list
      - method: google.storage.buckets.get
      - method: google.storage.objects.get
      - method: google.storage.objects.list
      serviceName: storage.googleapis.com
      resources:
      - projects/200612033880 # Google Cloud Example Project
```

## Usage

Once all the requirements are set up, you can start by running and adjusting the notebook step-by-step.

To run the notebook, open the Google Cloud Console on Vertex AI Workbench, open JupyterLab and upload the notebook (`multimodal_rag_langchain.ipynb`) to it.

### Optional: Use `terraform output` and bash command to fill in fields in the notebook

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
