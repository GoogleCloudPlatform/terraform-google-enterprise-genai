# Multimodal RAG Langhain Example

## Overview

Retrieval augmented generation (RAG) has become a popular paradigm for enabling LLMs to access external data and also as a mechanism for grounding to mitigate against hallucinations.

In this notebook, you will perform multimodal RAG by performing Q&A over a financial document filled with both text and images.

This example is an adapted version of the sample Generative AI notebook from the Google Cloud codebase. You can find the original example and other notebooks in the following repository: [Google Cloud Platform Generative AI](https://github.com/GoogleCloudPlatform/generative-ai/tree/main).

The main modifications to the original example include:

- Adaptations to comply with Cloud Foundation Toolkit security measures.
- Installation of additional libraries in the Conda environment.
- Use of Vertex AI Workbench to run the notebook with a custom Service Account.
- Implementation of Vector Search on Vertex AI with [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect).

## Requirements

- Terraform
- Authenticated Google Cloud SDK

### Provision Infrastructure with Terraform

- Update the `terraform.tfvars` file with values from your environment.
  - The code below is an example using the Development environment host VPC network, the env-level kms key for the machine learning project and the machine learning project.

    ```terraform
    kms_key                   = "projects/prj-d-kms-cau3/locations/us-central1/keyRings/ml-env-keyring/cryptoKeys/prj-d-ml-machine-learning"
    network                   = "projects/prj-d-shared-restricted-83dn/global/networks/vpc-d-shared-restricted"
    subnet                    = "projects/prj-d-shared-restricted-83dn/regions/us-central1/subnetworks/sb-d-shared-restricted-us-central1"
    machine_learning_project  = "prj-d-ml-machine-learning-0v09"
    vector_search_vpc_project = "prj-d-shared-restricted-83dn"
    ```

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

Once all the requirements are set up, you can begin by running and adjusting the notebook step-by-step.

To run the notebook, open the Google Cloud Console on Vertex AI Workbench, open jupyterlab and upload the notebook (`multimodal_rag_langchain.ipynb`) to it.

### Optional: Use `terraform output` and bash command to fill in fields in the notebook

You can save some time adjusting the notebook by running the commands below:

```bash
sed -i "s/<INSERT_PRIVATE_IP_VALUE_HERE>/$(terraform output -raw private_endpoint_ip_address)/g" multimodal_rag_langchain.ipynb
sed -i "s/<INSERT_HOST_VPC_PROJECT_ID>/$(terraform output -raw host_vpc_project_id)/g" multimodal_rag_langchain.ipynb
sed -i "s/<INSERT_NOTEBOOK_PROJECT_ID>/$(terraform output -raw notebook_project_id)/g" multimodal_rag_langchain.ipynb
sed -i "s/<INSERT_BUCKET_NAME>/$(terraform output -raw vector_search_bucket_name)/g" multimodal_rag_langchain.ipynb 
sed -i "s:<INSERT_HOST_VPC_NETWORK>:$(terraform output -raw host_vpc_network):g" multimodal_rag_langchain.ipynb
```

## Known Issues

- `Error: Error creating Instance: googleapi: Error 400: value_to_check(https://compute.googleapis.com/compute/v1/projects/...) is not found`.
  - When creating the VertexAI Workbench Instance through terraform you might face this issue. The issue is being tracked on this [link](https://github.com/hashicorp/terraform-provider-google/issues/17904).
  - If you face this issue you will not be able to use terraform to create the instance, therefore, you will need to manually create it on Google Cloud Console using the same parameters.