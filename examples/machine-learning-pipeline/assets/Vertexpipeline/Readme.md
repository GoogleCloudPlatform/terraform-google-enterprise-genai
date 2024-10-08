Machine learning pipeline from development to production

# Use case
This example illustrates the promotion of a a machine learning pipeline from an interactive tenant to a production tenant. The example specifically trains a model on a [UCI census dataset](%28https://archive.ics.uci.edu/dataset/20/census+income%29)
for binary classification.
The steps in the vertex pipelines version of the pipeline are as follows.
*This pipeline is also replicated with airflow operators for cloud composer.*
## Bigquery dataset creation
In the first step, a bigquery dataset is created using a bigquery operator offered by google as such:

    create_bq_dataset_query = f"""
        CREATE SCHEMA IF NOT EXISTS {DATASET_ID}
        """

    bq_dataset_op = BigqueryQueryJobOp(
        query=create_bq_dataset_query,
        project=project,
        location=region,
    )

Note that the default encryption key for bigquery is set after the projecet inflation so you don't have to pass the key in every query.

## Dataflow for data ingestion

Dataflow operator from google operators is used to ingest data raw data from a gcs bucket to bigquery tabels under our directory.

    dataflow_args_train = build_dataflow_args(
        job_name=f"{job_name}train",
        url=train_data_url,
        bq_dataset=bq_dataset,
        bq_table=bq_train_table,
        runner=runner,
        bq_project=project,
        subnet=dataflow_subnet
    ).after(bq_dataset_op)

     dataflow_python_train_op = DataflowPythonJobOp(
        requirements_file_path=requirements_file_path,
        python_module_path=python_file_path,
        args=dataflow_args_train.output,
        project=project,
        location=region,
        temp_location=f"{dataflow_temp_location}/train",
    ).after(dataflow_args_train)

    dataflow_wait_train_op = WaitGcpResourcesOp(
        gcp_resources=dataflow_python_train_op.outputs["gcp_resources"]
    ).after(dataflow_python_train_op)

## Model training

Once the data lands in the tables, the costume training process kick starts

    custom_training_task = custom_job_distributed_training_op(
        lr=lr,
        epochs=epochs,
        project=project,
        table=bq_train_table,
        dataset=bq_dataset,
        location=region,
        base_output_directory=base_train_dir,
        tb_log_dir=tb_log_dir,
        batch_size=batch_size
    ).after(dataflow_wait_train_op)


## Model evaluation

After the training, a custom evaluation step will determine whether the model qualifies for deployment:

    custom_eval_task = custom_eval_model(
        model_dir=model_dir,
        project=project,
        table=bq_eval_table,
        dataset=bq_dataset,
        tb_log_dir=tb_log_dir,
        model=custom_training_task.outputs["model"],
        batch_size=batch_size,
    )

## Deployment

If the model meets the requirements, deployment in production takes place (More details in the next section). Note that CMEK encryption is used in the deployment step which includes all of endpoint creation, uploading the model to vertex AI and versioning, and deploying the model to the endpoint.

    with dsl.If(
        custom_eval_task.outputs["dep_decision"] == "true",
        name="deploy_decision",
    ):
        model_deploy_op = deploy_model(
            serving_container_image_uri=deployment_image,
            model_name=deployed_model_name,
            endpoint_name=endpoint_name,
            project_id=deployment_project,
            region=region,
            split=traffic_split,
            model=custom_training_task.outputs['model'],
            model_dir=model_dir,
            min_nodes=min_nodes,
            max_nodes=max_nodes,
            encryption=encryption,
        ).after(custom_eval_task)


# Model monitoring

A model monitoring job starts to deploy on the model endpoint to monitor for skew and drift. Note that this component takes CMEK encryption as an argument:

    monitroing_job = create_monitoring(
            monitoring_name=monitoring_name,
            project_id=deployment_project,
            region=region,
            endpoint=model_deploy_op.outputs['vertex_endpoint'],
            bq_data_uri=f"bq://{project}.{bq_dataset}.{bq_train_table}",
            bucket_name=bucket_name,
            email=monitoring_email,
            encryption=encryption,
            service_account=service_account
        ).after(model_deploy_op)

# Pipeline job execution

The following method runs the pipeline. Note that a kms encryption key is supplied to be used when submitting the job to Vertex AI. This same key by default will be used to create the associated metadata store. If you deployed your own metadata store using the service catalog beforehand, you can adjust the pipeline and use its' key here.

```pipeline = aiplatform.PipelineJob(
    display_name=f"census_income_{timestamp}",
    template_path='./common/vertex-ai-pipeline/pipeline_package.yaml',
    pipeline_root=pipelineroot,
    encryption_spec_key_name='projects/prj-d-kms-ui2h/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-d-ml-machine-learning',
    parameter_values={
        "create_bq_dataset_query": create_bq_dataset_query,
        "bq_dataset": data_config['bq_dataset'],
        "bq_train_table": data_config['bq_train_table'],
        "bq_eval_table": data_config['bq_eval_table'],
        "job_name": dataflow_config['job_name'],
        "train_data_url": data_config['train_data_url'],
        "eval_data_url": data_config['eval_data_url'],
        "python_file_path": dataflow_config['python_file_path'],
        "dataflow_temp_location": dataflow_config['temp_location'],
        "runner": dataflow_config['runner'],
        "dataflow_subnet": dataflow_config['subnet'],
        "project": PROJECT_ID,
        "region": REGION,
        "model_dir": f"{BUCKET_URI}",
        "bucket_name": BUCKET_URI[5:],
        "epochs": train_config['epochs'],
        "lr": train_config['lr'],
        "base_train_dir": train_config['base_train_dir'],
        "tb_log_dir": train_config['tb_log_dir'],
        "deployment_image": deployment_config['image'],
        "deployed_model_name": deployment_config["model_name"],
        "endpoint_name": deployment_config["endpoint_name"],
        "min_nodes": deployment_config["min_nodes"],
        "max_nodes": deployment_config["max_nodes"],
        "deployment_project": deployment_config["deployment_project"],
        "encryption": deployment_config.get("encryption"),
        "service_account": deployment_config["service_account"],
        "prod_service_account": deployment_config["prod_service_account"],
        "monitoring_name": monitoring_config['name'],
        "monitoring_email": monitoring_config['email'],

    },
    enable_caching=False,
)
```


# Promotion workflow

The interactive (dev) tenant is where the experimentation takes place. Once a training algorithm is chosen and the ML pipeline steps are outlined, the pipeline is created using vertex pipeline components (managed kubeflow). This ML pipeline is configured such that it runs in non-prod (staging), however, the deployment and the model monitoring steps take place in prod. This is to save training resources as the data is already available in non-prod (staging).

> graph

Once the data scientist creates their pipeline they can push (the pipeline.yaml and code to run the pipeline) to a dev branch on git and create a PR to the staging branch. Once merged, cloud build will:

 - Install the dependencies
 - run the scripts to generate the pipeline.yaml file and run the the pipeline
 - upload the pipeline.yaml to the composer bucket on gcs (for scheduled runs)

The first version of the of model is trained and deployed due to the cloud build trigger. However, to keep the model up to date with incoming data, a simple composer dag is configured to run the same pipeline on scheduled intervals.

Note: For the first iteration, the pipeline.yaml file is generated and directly pushed to the repo. However, this can be done as a cloud build step as well in order to integrate security checks.

## Service accounts
Note that the is triggered by cloud build (for the first time) and cloud composer (for the scheduled run). Therefore, by default the respective service accounts are used for the vertex pipeline run. However, in our code we have configured two service accounts to run different steps.

- The bigquery service agent on the non-prod project will need EncryptDecrypt permission on the kms key so that it can create the dataset using the CMEK key.
 - First, a non-prod service account to take care of components that run in non-prod (dataset creation, dataflow, training, and evaluation). This could simply be the default compute engine service account for the non-prod tenant. This service account needs write permission to upload the trained model from the non-prod bucket to the Vertex environment of prod.
 - Another service account that has permissions on the prod tenant in order to deploy the model and the model monitoring job. This could simply be the default service account for the prod tenant. This service account will also need read permission on bigquery of non-prod where the data exists so that the monitoring job deployed by this service account in prod
