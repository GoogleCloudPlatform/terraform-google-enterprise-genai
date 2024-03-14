# Overview
This environment is set up for interactive coding and experimentations. After the project is up, the vertex workbench is deployed from service catalog and The datascientis can use it to write their code including any experiments, data processing code and pipeline components. In addition, a cloud storage bucket is deployed to use as the storage for our operations. Optionally a composer environment is which will later be used to schedule the pipeline run on intervals.

For our pipeline which trains and deploys a model on the [census income dataset](https://archive.ics.uci.edu/dataset/20/census+income), we use a notebook in the dev workbench to create our pipeline components, put them together into a pipeline and do a dry run of the pipeline to make sure there are no issues. You can access the repository [here](https://github.com/badal-io/vertexpipeline-promotion/tree/dev). [^1]

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

You can read more about the details of the pipeline components on the [pipeline's repo](https://github.com/badal-io/vertexpipeline-promotion/tree/dev?tab=readme-ov-file#use-case)

# Step by step
### 1. Run the notebook 
- Fork the repository to make you own copy on git. Clone it in the workbench in dev and run [the notebook](https://github.com/badal-io/vertexpipeline-promotion/blob/dev/census_pipeline.ipynb) cell by cell. Don't forget to set the correct values corresponding to your dev project.

### 2. Configure cloud build
- After the notebook runs successfully and the pipeline's test run finishes in the dev environment, create a cloud build trigger in your non-prod project. Configure the trigger to run when there is a merge into the staging (non-prod) branch. 

- Open the cloudbuild.yaml file in your workbench and for steps 1 and 2, replace the bucket name with the name of your own bucket in the non-prod project

- Change the name of the image for step 3 and 4 to that of your own artifact project, i.e., `us-central1-docker.pkg.dev/{artifact_project_id}/c-publish-artifacts/vertexpipeline:v2` This is the project with artifact registry that houses the image required to run the pipeline

- Optionally if you want to schedule pipeline runs on regular intervals, replace the composer bucket in the final step with your own composer bucket. Otherwise comment this step out.

### 3. Configure variables in compile_pipeline.py and runpipeline.py
- Make sure to set the correct values for variables like **PROJECT_ID**, **BUCKET_URI**, encryption keys and service accounts:

    |variable|definition|example value|
    |--------|----------|-----|
    |PROJECT_ID|The id of the non-prod project|`prj-n-bu3machine-learning-98j2`|
    |BUCKET_URI|URI of the non-prod bucket|`gs://bkt-n-ml-storage-snds`|
    |REGION|The region for pipeline jobs|Can be left as default `us-central1`|
    |PROD_PROJECT_ID|ID of the prod project|`prj-p-bu3machine-learning-98j2`|
    |DATAFLOW_SUBNET|The shared subnet in non-prod env required to run the dataflow job|`https://www.googleapis.com/compute/v1/projects/prj-n-shared-restricted-souc/regions/us-central1/subnetworks/sb-n-shared-restricted-us-central1`|
    |SERVICE_ACCOUNT|The service account used to run the pipeline and it's components such as the model monitoring job. This is the compute default service account of non-prod if you don't plan on using another costume service account|`{project_number}-compute@developer.gserviceaccount.com`|
    |PROD_SERICE_ACCOUNT|The service account used to create endpoint, upload the model, and deploy the model in the prod project. This is the compute default service account of prod if you don't plan on using another costume service account||
    |deployment_config['encryption']|The kms key for the prod env. This key is used to encrypt the vertex model, endpoint, model deployment, and model monitoring.|`projects/prj-p-kms-we3s/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-p-bu3machine-learning`|
    |encryption_spec_key_name|The name of the encryption key for the non-prod env. This key is used to create the vertex pipeline job and it's associated metadata store|`projects/prj-n-kms-we3s/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-n-bu3machine-learning`|
    |monitoring_config['email']|The email that Vertex AI monitoring will email alerts to|`your email`|
    
### 4. Merge and deploy
- Once everything is configured, you can commit your changes and push to the dev branch. Then, create a PR to from dev to staging(non-prod) which will result in triggering the pipeline if approved. The vertex pipeline takes about 30 minutes to finish and if there are no errors, a trained model will be deployed to and endpoint in the prod project which you can use to make prediction requests.