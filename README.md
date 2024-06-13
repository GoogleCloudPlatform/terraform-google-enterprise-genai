# terraform-google-enterprise-genai

## Overview

This repository serves as a example for configuring an environment for the development and deployment of Machine Learning applications using the Vertex AI platform on Google Cloud. It seamlessly integrates the Cloud Foundation Toolkit (CFT) and implements robust security measures, drawing heavily from the [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) codebase.

The repository is divided into distinct Terraform projects, each located in its own directory. These projects must be applied separately but in sequence. For detailed information about each step, please refer to [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0). The user has two options when deploying this codebase:

- Following the individual project steps as outlined in this repository, under `0-bootstrap` to `5-appinfra` directories.
- Deploy the codebase on top of an existing Enterprise Foundations Blueprint instance by following the steps detailed in [`docs/deploy_on_foundation_v4.0.0.md`](./docs/deploy_on_foundation_v4.0.0.md).
  > NOTE: If the user currently does not have a Enterprise Foundations Blueprint deployed, he can follow the steps outlined in [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) to deploy it.

## Main Modifications made to Enterprise Foundations Blueprint

- [1. org](./1-org/)
  - Specific to this repository, it will also configure Machine Learning Organization Policies.
  - Create Organization Level Keyring.
- [2. environments](./2-environments/)
  - This repository will also establish organization and environment-level Cloud Key Management Service (KMS) keyrings during this stage.
- [3. networks-dual-svpc](./3-networks-dual-svpc/)
  - On this repository, it will also configure a private DNS zone for workbench instances to use either `private.googleapis.com` or `restricted.googleapis.com`.
  - Custom firewall rules.
  - Enable Cloud NAT.
- [4. projects](./4-projects/)
  - Instead of creating `business_unit_1` and `business_unit_2`, this repository will create `ml_business_unit`.
  - Additionally, it will establish a Service Catalog project capable of hosting terraform solutions and an artifacts project.
  - Will create a Machine Learning project for each environment.
- [5. app-infra](./5-app-infra/)  
  - Deploys a Service Catalog Pipeline, that can be used for packaging terraform modules.
  - Creates an Artifacts Pipeline, that can be used to create organization-wide custom docker images.

## Examples

- [genai-rag-multimodal](./examples/genai-rag-multimodal)
  - Multimodal RAG by performing Q&A over a financial document filled with both text and images.
  - Use RAGAS for RAG chain evaluation.

- [machine-learning-pipeline](./6-ml-pipeline/)
  - This example, adds an interactive coding and experimentation, deploying the Vertex Workbench for data scientists.
  - The step will guide you through creating a ML pipeline using a notebook on Google Vertex AI Workbench Instance.
  - After promoting the ML pipeline, it is triggered by Cloud Build upon staging branch merges, trains and deploys a model using the census income dataset.
  - Model deployment and monitoring occur in the prod environment.
  - Following successful pipeline runs, a new model version is deployed for A/B testing.
