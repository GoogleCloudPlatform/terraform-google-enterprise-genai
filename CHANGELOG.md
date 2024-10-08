# Changelog

## 0.1.0 (2024-10-08)


### Features

* add machine learning organization policies module ([#34](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/34)) ([e291cda](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/e291cda0be551060b940abf99c57c247b7461583))
* add ml policies ([0ec0c87](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/0ec0c8750b3198b533bd02a5d6194fc6c40aa724))
* **docs:** Add 5-appinfra instructions to deploy on foundation docs ([#49](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/49)) ([e95edf3](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/e95edf344709a430bc30d889bbb42fbfb21a661e))
* **example:** Add Generative AI example using RAG and Vector Search ([#46](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/46)) ([7472009](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/7472009670f483205c4dce85398ae313cd3d48cd))
* **examples:** Add RAGAS evaluation to RAG chain ([#50](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/50)) ([8f23e99](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/8f23e9948e91c34627e8194e89c7e4ead9992139))
* **examples:** Vertex  Machine Learning Pipeline ([#66](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/66)) ([ba52535](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/ba52535112f3d843619045806425bd6f95264c56))
* **module:** Add ML Infra Projects Module and 4-projects refactor ([#40](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/40)) ([fda06e1](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/fda06e1d2254fd06d60c07735c7126155ab5745e))
* **module:** refactor org-level and env-level KMS ([#38](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/38)) ([2e9d699](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/2e9d6990b1923fd722d00562ad037675d5b4ba4e))
* separate notebook dns module ([#36](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/36)) ([45a873d](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/45a873d7d74d2f4a9fdd66e70a1c67920f7b7ac3))


### Bug Fixes

* Add missing APIs ([#41](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/41)) ([77ddfcd](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/77ddfcd847e17a950e679762c216317a8e7dd7a9))
* add missing local ([c70b1b5](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/c70b1b558a0ddcc7dced5f242e2096ee8e660f73))
* adjust google_artifact_registry_repository_iam_member role assignment ([2765b80](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/2765b8063cfba4794a6e2b1f368f0631b1a9d969))
* adjusting deploy on foundation docs, cleaning files and 5-appinfra docs ([#65](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/65)) ([aea1dd9](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/aea1dd913595316fe67e5fa8a18c7482a8e41ee1))
* adjusting README steps, terraform version and breaking issues ([#64](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/64)) ([c85cab0](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/c85cab0483addc5ed7347291bcbe9df24cfec1ec))
* fixing conflicts ([e6eef0f](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/e6eef0fd6717b163516a0cefe5840a03fbab0b9d))
* fixing images ([07eddcb](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/07eddcb5097931a85992bfc2f5e772756e7d4c7b))
* fixing images ([ae572b3](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/ae572b370dd082503394a3d22a8d8d2861ec19a8))
* fixing some conflicts ([f688d61](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/f688d61538f5eeff6c897b8b624bfb6a001beea9))
* hardcoded values on backends adjust artifact-publish-repo documentation ([062de39](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/062de394d3ae1a307627e3625030aac66800486d))
* lint build corrections ([#35](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/35)) ([7f66948](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/7f66948cc27177eb4ac141f190ca37c31acb7ea8))
* refactoring to fit cloud build service account changes ([#52](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/52)) ([a7eacab](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/a7eacab7c965ea860ac553bf5906e84fef9a5b12))
* remove data source on service catalog and artifact publish ([#51](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/issues/51)) ([d3526ca](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/d3526ca6949620effdddb0dc52f0cbd9c4e8b9ba))
* remove kms hardcoded value ([6c7bf9c](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/6c7bf9cb86467c3d5788017705344fb7cf65bef4))
* remove more hardcoded values ([ba98e01](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/ba98e017f8c5315c94e8e38de6d95facdf2916eb))
* replace hardcoded bucket values in backend.tf ([1bfba13](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/1bfba13950a3f1a7a112058a4a4eafae8c2a0425))
* replace hardcoded bucket values in backend.tf ([a8d2245](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/a8d2245ffc8d31e7f92ea925a4912d61e32c386d))
* resolve conflicts ([0434649](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/043464948ce0ed1a310f74412e3ef0f8f821f44e))
* update hardcoded service catalog prj id + readme ([63580b7](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/commit/63580b7c567aff8e2b88c02847ec943c1e37be23))

## Changelog
