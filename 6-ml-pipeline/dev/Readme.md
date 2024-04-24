# Overview
This environment is set up for interactive coding and experimentations. After the project is up, the vertex workbench is deployed from service catalog and The datascientis can use it to write their code including any experiments, data processing code and pipeline components. In addition, a cloud storage bucket is deployed to use as the storage for our operations. Optionally a composer environment is which will later be used to schedule the pipeline run on intervals.

For our pipeline which trains and deploys a model on the [census income dataset](https://archive.ics.uci.edu/dataset/20/census+income), we use a notebook in the dev workbench to create our pipeline components, put them together into a pipeline and do a dry run of the pipeline to make sure there are no issues. You can access the repository [here](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/tree/main/7-vertexpipeline). [^1]

[^1]: There is a Dockerfile in the repo which is the docker image used to run all pipeline steps and cloud build steps. In non-prod and prod environments, the only NIST compliant way to access additional dependencies and requirements is via docker images uploaded to artifact registry. We have baked everything for running the pipeline into this docker which exsits in the shared artifact registry.

Once confident, we divide the code in two separate files to use in our CI/CD process in the non-prod environment. First is *compile_pipeline.py* which includes the code to build the pipeline and compile it into a directory (in our case, /common/vertex-ai-pipeline/pipeline_package.yaml)

The second file, i.e. *runpipeline.py* includes the code for running the compiled pipeline. This is where the correct environemnt variables for non-prod nad prod (e.g., service accounts to use for each stage of the pipeline, kms keys corresponding to each step, buckets, etc.) are set. And eventually the pipeline is loaded from the yaml file at *common/vertex-ai-pipeline/pipeline_package.yaml* and submitted to vertex ai.


There is a *cloudbuild.yaml* file in the repo with the CI/CD steps as follows:

1. Upload the Dataflow src file to the bucket in non-prod
2. Upload the dataset to the bucket
3. Run *compile_pipeline.py* to compile the pipeline
4. Run the pipeline via *runpipeline.py*
5. Optionally, upload the pipeline's yaml file to the composer bucket to make it available for scheduled pipeline runs

The cloud build trigger will be setup in the non-prod project which is where the ML pipeline will run. There are currently three branches on the repo namely dev, staging (non-prod), and prod. Cloud build will trigger the pipeline once there is a merge into the staging (non-prod) branch from dev. However, model deployment and monitorings steps take place in the prod environment. As a result, the service agents and service accounts of the non-prod environment are given some permission on the prod environment and vice versa.

Each time a pipeline job finishes successfully, a new version of the census income bracket predictor model will be deployed on the endpoint which will only take 25 percent of the traffic wherease the other 75 percent goes to the previous version of the model to enable A/B testing.

You can read more about the details of the pipeline components on the [pipeline's repo](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/tree/main/7-vertexpipeline#readme)

# Step by step
Before you start, make sure you have your personal git access token ready. The git menu option on the left bar of the workbench requires the personal token to connect to git and clone the repo.
Also make sure to have a gcs bucket ready to store the artifacts for the tutorial. To deploy the bucket, you can go to service catalog and create a new deployment from the storage bucket solution.
### 1. Run the notebook 
- Take 7-vertexpipeline folder and make you own copy as a standalone git repository and clone it in the workbench in your dev project. Create a dev branch of the new repository. Switch to the dev branch by choosing it in the branch section of the git view. Now go back to the file browser view by clicking the first option on the left bar menu. Navigate to the directory you just clone and run [the notebook](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/blob/main/7-vertexpipeline/census_pipeline.ipynb) cell by cell. Pay attention to the instructions and comments in the notebook and don't forget to set the correct values corresponding to your dev project.

### 2. Configure cloud build
- After the notebook runs successfully and the pipeline's test run finishes in the dev environment, create a cloud build trigger in your non-prod project. Configure the trigger to run when there is a merge into the staging (non-prod) branch by following the below settings.

    |Setting|Value|
    |-------|-----|
    |Event|push to branch|
    |Repository generation|1st gen|
    |Repository|the url to your fork of the repo|
    |Branch|staging|
    |Configuration|Autodetected/Cloud Build configuration file (yaml or json)|
    |Location|Repository|
    |Cloud Build configuration file location|cloudbuild.yaml|
    

- Open the cloudbuild.yaml file in your workbench and for steps 1 which uploads the source code for the dataflow job to your bucket.

    ```
    name: 'gcr.io/cloud-builders/gsutil'
    args: ['cp', '-r', './src', 'gs://{your-bucket-name}']
    ```

- Similarly in step 2, replace the bucket name with the name of your own bucket in the non-prod project in order to upload the data to your bucket:
    ```
    name: 'gcr.io/cloud-builders/gsutil'
    args: ['cp', '-r', './data', 'gs://{your-bucket-name}']
    ```

- Change the name of the image for step 3 and 4 to that of your own artifact project, i.e., `us-central1-docker.pkg.dev/{artifact_project_id}/c-publish-artifacts/vertexpipeline:v2` This is the project with artifact registry that houses the image required to run the pipeline.

```
 - name: 'us-central1-docker.pkg.dev/{your-artifact-project}/c-publish-artifacts/vertexpipeline:v2'
    entrypoint: 'python'
    args: ['compile_pipeline.py']
    id: 'compile_job'
  
  # run pipeline
  - name: 'us-central1-docker.pkg.dev/{your-artifact-project}/c-publish-artifacts/vertexpipeline:v2'
    entrypoint: 'python'
    args: ['runpipeline.py']
    id: 'run_job'
    waitFor: ['compile_job']
```

- Optionally, if you want to schedule pipeline runs on regular intervals, uncomment the last two steps and replace the composer bucket with the name of your composer's bucket. The first step uploads the pipeline's yaml to the bucket and the second step uploads the dag to read that yaml and trigger the vertex pipeline:
```
 # upload to composer
   - name: 'gcr.io/cloud-builders/gsutil'
     args: ['cp', './common/vertex-ai-pipeline/pipeline_package.yaml', 'gs://{your-composer-bucket}/dags/common/vertex-ai-pipeline/']
     id: 'upload_composer_file'
     
 # upload pipeline dag to composer
    - name: 'gcr.io/cloud-builders/gsutil'
      args: ['cp', './composer/dags/dag.py', 'gs://{your-composer-bucket}/dags/']
      id: 'upload dag'
```

### 3. Configure variables in compile_pipeline.py and runpipeline.py
- Make sure to set the correct values for variables like **PROJECT_ID**, **BUCKET_URI**, encryption keys and service accounts, etc.:

    |variable|definition|example value|How to obtain|
    |--------|----------|-------------|-------------|
    |PROJECT_ID|The id of the non-prod project|`{none-prod-project-id}`|From the project's menu in console navigate to the `fldr-non-production/fldr-non-production-bu3` folder; here you can find the machine learning project in non-prod (`prj-n-bu3machine-learning`) and obtain its' ID|
    |BUCKET_URI|URI of the non-prod bucket|`gs://non-prod-bucket`|From the project menu in console navigate to the non-prod ML project `fldr-non-production/fldr-non-production-bu3/prj-n-bu3machine-learning` project, navigate to cloud storage and copy the name of the bucket available there|
    |REGION|The region for pipeline jobs|Can be left as default `us-central1`|
    |PROD_PROJECT_ID|ID of the prod project|`prod-project-id`|In console's project menu, navigate to the `fldr-production/fldr-production-bu3` folder; here you can find the machine learning project in prod (`prj-p-bu3machine-learning`) and obtain its' ID|
    |Image|The image artifact used to run the pipeline components. The image is already built and pushed to the artifact repository in your artifact project under the common folder|`f"us-central1-docker.pkg.dev/{{artifact-project}}/{{artifact-repository}}/vertexpipeline:v2"`|Navigate to `fldr-common/prj-c-bu3artifacts` project. Navigate to the artifact registry repositories in the project to find the full name of the image artifact.|
    |DATAFLOW_SUBNET|The shared subnet in non-prod env required to run the dataflow job|`https://www.googleapis.com/compute/v1/projects/{non-prod-network-project}/regions/us-central1/subnetworks/{subnetwork-name}`|Navigate to the `fldr-network/prj-n-shared-restricted` project. Navigate to the VPC networks and under the subnets tab, find the name of the network associated with your region (us-central1)|
    |SERVICE_ACCOUNT|The service account used to run the pipeline and it's components such as the model monitoring job. This is the compute default service account of non-prod if you don't plan on using another costume service account|`{non-prod-project_number}-compute@developer.gserviceaccount.com`|Head over to the IAM page in the non-prod project `fldr-non-production/fldr-non-production-bu3/prj-n-bu3machine-learning`, check the box for `Include Google-provided role grants` and look for the service account with the `{project_number}-compute@developer.gserviceaccount.com`|
    |PROD_SERICE_ACCOUNT|The service account used to create endpoint, upload the model, and deploy the model in the prod project. This is the compute default service account of prod if you don't plan on using another costume service account|`{prod-project_number}-compute@developer.gserviceaccount.com`|Head over to the IAM page in the prod project `fldr-production/fldr-production-bu3/prj-p-bu3machine-learning`, check the box for `Include Google-provided role grants` and look for the service account with the `{project_number}-compute@developer.gserviceaccount.com`|
    |deployment_config['encryption']|The kms key for the prod env. This key is used to encrypt the vertex model, endpoint, model deployment, and model monitoring.|`projects/{prod-kms-project}/locations/us-central1/keyRings/{keyring-name}/cryptoKeys/{key-name}`|Navigate to `fldr-production/prj-n-kms`, navigate to the Security/Key management in that project to find the key in `sample-keyring` keyring of your target region `us-central1`|
    |encryption_spec_key_name|The name of the encryption key for the non-prod env. This key is used to create the vertex pipeline job and it's associated metadata store|`projects/{non-prod-kms-project}/locations/us-central1/keyRings/{keyring-name}/cryptoKeys/{key-name}`|Navigate to `fldr-non-production/prj-n-kms`, navigate to the Security/Key management in that project to find the key in `sample-keyring` keyring of your target region `us-central1`|
    |monitoring_config['email']|The email that Vertex AI monitoring will email alerts to|`your email`|your email associated with your gcp account|

The compile_pipeline.py and runpipeline.py files are commented to point out these variables.
### 4. Merge and deploy
- Once everything is configured, you can commit your changes and push to the dev branch. Then, create a PR to from dev to staging(non-prod) which will result in triggering the pipeline if approved. The vertex pipeline takes about 30 minutes to finish and if there are no errors, a trained model will be deployed to and endpoint in the prod project which you can use to make prediction requests.




# Common errors
- ***google.api_core.exceptions.ResourceExhausted: 429 The following quotas are exceeded: ```CustomModelServingCPUsPerProjectPerRegion 8: The following quotas are exceeded: CustomModelServingCPUsPerProjectPerRegion``` or similar error***:
This is likely due to the fact that you have too many models uploaded and deployed in Vertex AI. To resolve the issue, you can either submit a quota increase request or undeploy and delete a few models to free up resources

- ***Google Compute Engine Metadata service not available/found***:
You might encounter this when the vertex pipeline job attempts to run even though it is an obsolete issue according to [this thread](https://issuetracker.google.com/issues/229537245#comment9). It'll most likely resolve by re-running the vertex pipeline
