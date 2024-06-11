# terraform-google-enterprise-genai

## Overview

This repository serves as a example for configuring an environment for the development and deployment of Machine Learning applications using the Vertex AI platform on Google Cloud. It seamlessly integrates the Cloud Foundation Toolkit (CFT) and implements robust security measures, drawing heavily from the [terraform-google-enterprise-genai](https://github.com/terraform-google-modules/terraform-google-enterprise-genai/tree/v4.0.0) codebase.

The repo is separated in distinct Terraform projects, each within their own directory that must be applied separately, but in sequence, for more information about each step, please refer to [terraform-google-enterprise-genai](https://github.com/terraform-google-modules/terraform-google-enterprise-genai/tree/v4.0.0). Comparing to the foundation repository, the key differences from the steps in foundation to steps in these repository are:

* [1. org](./1-org/)
    * Specific to this repository, it will also configure Machine Learning Organization Policies.
* [2. environments](./2-environments/)
    * This repository will also establish organization and environment-level Cloud Key Management Service (KMS) keyrings during this stage.
* [3. networks-dual-svpc](./3-networks-dual-svpc/)
    * On this repository, it will also configure a private DNS zone for workbench instances to use either `private.googleapis.com` or `restricted.googleapis.com`.
* [4. projects](./4-projects/)
    * Instead of creating `business_unit_1` and `business_unit_2`, this repository exclusively creates `business_unit_3`.
    * Additionally, it will establish a Service Catalog project capable of hosting terraform solutions and an artifacts project.
    * Will create a Machine Learning project for each environment.
* [5. app-infra](./5-app-infra/)
    * The purpose of this step is to execute a series of steps necessary to deploy and run a Machine Learning Application.

Additional steps were added to provide an example Machine Learning application:

* [6. ml-pipeline](./6-ml-pipeline/)
    * This additional step, adds an interactive coding and experimentation, deploying the Vertex Workbench for data scientists.
    * The step will guide you through creating a ML pipeline using a notebook on Google Vertex AI Workbench Instance.
    * After promoting the ML pipeline, it is triggered by Cloud Build upon staging branch merges, trains and deploys a model using the census income dataset.
    * Model deployment and monitoring occur in the prod environment.
    * Following successful pipeline runs, a new model version is deployed for A/B testing.

* [7. composer](./7-composer/)
    * Used for code reference.

* [7. vertexpipeline](./7-vertexpipeline/)
    * Used for code reference, will be used for creating the Machine Learning pipeline.
