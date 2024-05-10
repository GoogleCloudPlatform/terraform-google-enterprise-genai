# terraform-google-enterprise-genai

## Overview

This repository serves as a example for configuring an environment for the development and deployment of Machine Learning applications using the Vertex AI platform on Google Cloud. It seamlessly integrates the Cloud Foundation Toolkit (CFT) and implements robust security measures, drawing heavily from the [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) codebase.

The repo is separated in distinct Terraform projects, each within their own directory that must be applied separately, but in sequence, for more information about each step, please refer to [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0). Comparing to the foundation repository, the key differences from the steps in foundation to steps in these repository are:

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