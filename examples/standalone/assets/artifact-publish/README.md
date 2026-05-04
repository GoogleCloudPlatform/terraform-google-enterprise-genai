# ml-foundations-docker
Dockerfile repository for the ml-foundations artifacts project.

This repository hosts custom container images that are automatically built via Cloud Build and published to the central Artifact Registry (`common` shared project).

### Usage in Machine Learning Pipelines Example

The images defined in the `images/` directory are required to run the **Vertex AI and Airflow (Cloud Composer) machine learning pipelines** demonstrated in the `examples/machine-learning-pipeline` directory. These images are built and published to Artifact Registry by this repository.
