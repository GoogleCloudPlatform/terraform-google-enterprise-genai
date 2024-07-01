# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# flake8: noqa
from kfp.dsl import component
from kfp import components
from kfp import compiler, dsl
from google_cloud_pipeline_components.v1.custom_job import utils
from kfp.dsl import Input, Output, Model, Metrics, OutputPath
from typing import NamedTuple

# Replace with your non-prod project ID
PROJECT_ID = "{project-id}"
# Replace with your region only if different
REGION = "us-central1"
# Repalce with your bucket's uri
BUCKET_URI = "gs://{bucket-name}"

KFP_COMPONENTS_PATH = "components"
SRC = "src"
BUILD = "build"
# Replace {artifact-project} and {artifact-repository}
# with your artifact project and repository
Image = f"us-central1-docker.pkg.dev/{{artifact-project}}/{{artifact-repository}}/vertexpipeline:v2"


DATA_URL = f'{BUCKET_URI}/data'
TRAINING_FILE = 'adult.data.csv'
EVAL_FILE = 'adult.test.csv'
TRAINING_URL = '%s/%s' % (DATA_URL, TRAINING_FILE)
EVAL_URL = '%s/%s' % (DATA_URL, EVAL_FILE)
DATASET_ID = 'census_dataset'
TRAINING_TABLE_ID = 'census_train_table'
EVAL_TABLE_ID = 'census_eval_table'
RUNNER = "DataflowRunner"
REGION = "us-central1"
JOB_NAME = "census-ingest"
UNUSED_COLUMNS = ["fnlwgt", "education_num"]


@component(base_image=Image)
def build_dataflow_args(
    bq_dataset: str,
    url: str,
    bq_table: str,
    job_name: str,
    runner: str,
    bq_project: str,
    subnet: str,
    dataflow_sa: str,
) -> list:
    return [
        "--job_name",
        job_name,
        "--runner",
        runner,
        "--url",
        url,
        "--bq-dataset",
        bq_dataset,
        "--bq-table",
        bq_table,
        "--bq-project",
        bq_project,
        "--subnetwork",
        subnet,
        "--no_use_public_ips",
        "--worker_zone",
        "us-central1-c",
        "--service_account_email",
        dataflow_sa,
    ]
# build_dataflow_args = components.create_component_from_func(
#     build_dataflow_args_fun, base_image='python:3.8-slim')


@component(base_image=Image)
def custom_train_model(
    project: str,
    table: str,
    dataset: str,
    tb_log_dir: str,
    model: Output[Model],
    epochs: int = 5,
    batch_size: int = 32,
    lr: float = 0.01,  # not used here but can be passed to an optimizer
):

    from tensorflow.python.framework import ops
    from tensorflow.python.framework import dtypes
    from tensorflow_io.bigquery import BigQueryClient
    from tensorflow_io.bigquery import BigQueryReadSession
    from tensorflow import feature_column
    from google.cloud import bigquery

    import tensorflow as tf
    CSV_SCHEMA = [
        bigquery.SchemaField("age", "FLOAT64"),
        bigquery.SchemaField("workclass", "STRING"),
        bigquery.SchemaField("fnlwgt", "FLOAT64"),
        bigquery.SchemaField("education", "STRING"),
        bigquery.SchemaField("education_num", "FLOAT64"),
        bigquery.SchemaField("marital_status", "STRING"),
        bigquery.SchemaField("occupation", "STRING"),
        bigquery.SchemaField("relationship", "STRING"),
        bigquery.SchemaField("race", "STRING"),
        bigquery.SchemaField("gender", "STRING"),
        bigquery.SchemaField("capital_gain", "FLOAT64"),
        bigquery.SchemaField("capital_loss", "FLOAT64"),
        bigquery.SchemaField("hours_per_week", "FLOAT64"),
        bigquery.SchemaField("native_country", "STRING"),
        bigquery.SchemaField("income_bracket", "STRING"),
    ]

    UNUSED_COLUMNS = ["fnlwgt", "education_num"]

    def transform_row(row_dict):
        # Trim all string tensors
        trimmed_dict = {column:
                        (tf.strings.strip(tensor)
                         if tensor.dtype == 'string' else tensor)
                        for (column, tensor) in row_dict.items()
                        }
        # Extract feature column
        income_bracket = trimmed_dict.pop('income_bracket')
        # Convert feature column to 0.0/1.0
        income_bracket_float = tf.cond(tf.equal(tf.strings.strip(income_bracket), '>50K'),
                                       lambda: tf.constant(1.0),
                                       lambda: tf.constant(0.0))
        return (trimmed_dict, income_bracket_float)

    def read_bigquery(table_name, dataset=dataset):
        tensorflow_io_bigquery_client = BigQueryClient()
        read_session = tensorflow_io_bigquery_client.read_session(
            "projects/" + project,
            project, table, dataset,
            list(field.name for field in CSV_SCHEMA
                 if not field.name in UNUSED_COLUMNS),
            list(dtypes.double if field.field_type == 'FLOAT64'
                 else dtypes.string for field in CSV_SCHEMA
                 if not field.name in UNUSED_COLUMNS),
            requested_streams=2)

        dataset = read_session.parallel_read_rows()
        transformed_ds = dataset.map(transform_row)
        return transformed_ds

    training_ds = read_bigquery(table).shuffle(10000).batch(batch_size)

    feature_columns = []

    def get_categorical_feature_values(column):
        query = 'SELECT DISTINCT TRIM({}) FROM `{}`.{}.{}'.format(
            column, project, dataset, table)
        client = bigquery.Client(project=project)
        dataset_ref = client.dataset(dataset)
        job_config = bigquery.QueryJobConfig()
        query_job = client.query(query, job_config=job_config)
        result = query_job.to_dataframe()
        return result.values[:, 0]

    # numeric cols
    for header in ['capital_gain', 'capital_loss', 'hours_per_week']:
        feature_columns.append(feature_column.numeric_column(header))

    # categorical cols
    for header in ['workclass', 'marital_status', 'occupation', 'relationship',
                   'race', 'native_country', 'education']:
        categorical_feature = feature_column.categorical_column_with_vocabulary_list(
            header, get_categorical_feature_values(header))
        categorical_feature_one_hot = feature_column.indicator_column(
            categorical_feature)
        feature_columns.append(categorical_feature_one_hot)

    # bucketized cols
    age = feature_column.numeric_column('age')
    age_buckets = feature_column.bucketized_column(
        age, boundaries=[18, 25, 30, 35, 40, 45, 50, 55, 60, 65])
    feature_columns.append(age_buckets)

    feature_layer = tf.keras.layers.DenseFeatures(feature_columns)

    Dense = tf.keras.layers.Dense
    keras_model = tf.keras.Sequential(
        [
            feature_layer,
            Dense(100, activation=tf.nn.relu, kernel_initializer='uniform'),
            Dense(75, activation=tf.nn.relu),
            Dense(50, activation=tf.nn.relu),
            Dense(25, activation=tf.nn.relu),
            Dense(1, activation=tf.nn.sigmoid)
        ])

    tensorboard = tf.keras.callbacks.TensorBoard(log_dir=tb_log_dir)
    # Compile Keras model
    keras_model.compile(loss='binary_crossentropy', metrics=['accuracy'])
    keras_model.fit(training_ds, epochs=epochs, callbacks=[tensorboard])
    keras_model.save(model.path)


# custom_train_model = components.create_component_from_func(
#     custom_train_model_fun, base_image=Image)
custom_job_distributed_training_op = utils.create_custom_training_job_op_from_component(
    custom_train_model, replica_count=1
)


@component(base_image=Image)
def custom_eval_model(
    model_dir: str,
    project: str,
    table: str,
    dataset: str,
    tb_log_dir: str,
    model: Input[Model],
    metrics: Output[Metrics],
    batch_size: int = 32,
) -> NamedTuple("Outputs", [("dep_decision", str)]):
    from tensorflow.python.framework import ops
    from tensorflow.python.framework import dtypes
    from tensorflow_io.bigquery import BigQueryClient
    from tensorflow_io.bigquery import BigQueryReadSession
    from tensorflow import feature_column
    from google.cloud import bigquery

    import tensorflow as tf
    CSV_SCHEMA = [
        bigquery.SchemaField("age", "FLOAT64"),
        bigquery.SchemaField("workclass", "STRING"),
        bigquery.SchemaField("fnlwgt", "FLOAT64"),
        bigquery.SchemaField("education", "STRING"),
        bigquery.SchemaField("education_num", "FLOAT64"),
        bigquery.SchemaField("marital_status", "STRING"),
        bigquery.SchemaField("occupation", "STRING"),
        bigquery.SchemaField("relationship", "STRING"),
        bigquery.SchemaField("race", "STRING"),
        bigquery.SchemaField("gender", "STRING"),
        bigquery.SchemaField("capital_gain", "FLOAT64"),
        bigquery.SchemaField("capital_loss", "FLOAT64"),
        bigquery.SchemaField("hours_per_week", "FLOAT64"),
        bigquery.SchemaField("native_country", "STRING"),
        bigquery.SchemaField("income_bracket", "STRING"),
    ]

    UNUSED_COLUMNS = ["fnlwgt", "education_num"]

    def transform_row(row_dict):
        # Trim all string tensors
        trimmed_dict = {column:
                        (tf.strings.strip(tensor)
                         if tensor.dtype == 'string' else tensor)
                        for (column, tensor) in row_dict.items()
                        }
        # Extract feature column
        income_bracket = trimmed_dict.pop('income_bracket')
        # Convert feature column to 0.0/1.0
        income_bracket_float = tf.cond(tf.equal(tf.strings.strip(income_bracket), '>50K'),
                                       lambda: tf.constant(1.0),
                                       lambda: tf.constant(0.0))
        return (trimmed_dict, income_bracket_float)

    def read_bigquery(table_name, dataset=dataset):
        tensorflow_io_bigquery_client = BigQueryClient()
        read_session = tensorflow_io_bigquery_client.read_session(
            "projects/" + project,
            project, table, dataset,
            list(field.name for field in CSV_SCHEMA
                 if not field.name in UNUSED_COLUMNS),
            list(dtypes.double if field.field_type == 'FLOAT64'
                 else dtypes.string for field in CSV_SCHEMA
                 if not field.name in UNUSED_COLUMNS),
            requested_streams=2)

        dataset = read_session.parallel_read_rows()
        transformed_ds = dataset.map(transform_row)
        return transformed_ds

    eval_ds = read_bigquery(table).batch(batch_size)
    keras_model = tf.keras.models.load_model(model.path)
    tensorboard = tf.keras.callbacks.TensorBoard(log_dir=tb_log_dir)
    loss, accuracy = keras_model.evaluate(eval_ds, callbacks=[tensorboard])
    metrics.log_metric("accuracy", accuracy)

    if accuracy > 0.7:
        dep_decision = "true"
        keras_model.save(model_dir)
    else:
        dep_decision = "false"
    return (dep_decision,)


@component(base_image=Image)
def deploy_model(
        serving_container_image_uri: str,
        model_name: str,
        model_dir: str,
        endpoint_name: str,
        project_id: str,
        region: str,
        split: int,
        min_nodes: int,
        max_nodes: int,
        encryption: str,
        service_account: str,
        model: Input[Model],
        vertex_model: Output[Model],
        vertex_endpoint: Output[Model]
):
    from google.cloud import aiplatform
    aiplatform.init(service_account=service_account)

    def create_endpoint():
        endpoints = aiplatform.Endpoint.list(
            filter=f'display_name="{endpoint_name}"',
            order_by='create_time desc',
            project=project_id,
            location=region,
        )
        if len(endpoints) > 0:
            endpoint = endpoints[0]  # most recently created
        else:
            endpoint = aiplatform.Endpoint.create(
                display_name=endpoint_name,
                project=project_id,
                location=region,
                encryption_spec_key_name=encryption
            )
        return endpoint

    endpoint = create_endpoint()

    def upload_model():
        listed_model = aiplatform.Model.list(
            filter=f'display_name="{model_name}"',
            project=project_id,
            location=region,
        )
        if len(listed_model) > 0:
            model_version = listed_model[0]
            model_upload = aiplatform.Model.upload(
                display_name=model_name,
                parent_model=model_version.resource_name,
                artifact_uri=model_dir,
                serving_container_image_uri=serving_container_image_uri,
                location=region,
                project=project_id,
                encryption_spec_key_name=encryption
            )
        else:
            model_upload = aiplatform.Model.upload(
                display_name=model_name,
                artifact_uri=model_dir,
                serving_container_image_uri=serving_container_image_uri,
                location=region,
                project=project_id,
                encryption_spec_key_name=encryption,

            )
        return model_upload

    uploaded_model = upload_model()

    # Save data to the output params
    vertex_model.uri = uploaded_model.resource_name

    def deploy_to_endpoint(model, endpoint):
        deployed_models = endpoint.list_models()
        if len(deployed_models) > 0:
            latest_model_id = deployed_models[-1].id
            print("your objects properties:",
                  deployed_models[0].create_time.__dir__())
            model_deploy = uploaded_model.deploy(
                # machine_type="n1-standard-4",
                endpoint=endpoint,
                traffic_split={"0": 25, latest_model_id: 75},
                deployed_model_display_name=model_name,
                min_replica_count=min_nodes,
                max_replica_count=max_nodes,
                encryption_spec_key_name=encryption,
                service_account=service_account
            )
        else:
            model_deploy = uploaded_model.deploy(
                # machine_type="n1-standard-4",
                endpoint=endpoint,
                traffic_split={"0": 100},
                min_replica_count=min_nodes,
                max_replica_count=max_nodes,
                deployed_model_display_name=model_name,
                encryption_spec_key_name=encryption,
                service_account=service_account
            )
        return model_deploy.resource_name

    vertex_endpoint.uri = deploy_to_endpoint(vertex_model, endpoint)
    vertex_endpoint.metadata['resourceName'] = endpoint.resource_name


# deploy_model = components.create_component_from_func(
#     deploy_model_fun, base_image=Image)

@component(base_image=Image)
def create_monitoring(
    monitoring_name: str,
    project_id: str,
    region: str,
    endpoint: Input[Model],
    bq_data_uri: str,
    bucket_name: str,
    email: str,
    encryption: str,
    service_account: str,
):
    from google.cloud.aiplatform import model_monitoring
    from google.cloud import aiplatform
    from google.cloud import bigquery
    from google.cloud import storage
    from collections import OrderedDict
    import time
    import yaml

    # can be a lambda if that's what you prefer
    def ordered_dict_representer(self, value):
        return self.represent_mapping('tag:yaml.org,2002:map', value.items())
    yaml.add_representer(OrderedDict, ordered_dict_representer)

    aiplatform.init(service_account=service_account)
    list_monitors = aiplatform.ModelDeploymentMonitoringJob.list(
        filter=f'(state="JOB_STATE_SUCCEEDED" OR state="JOB_STATE_RUNNING") AND display_name="{monitoring_name}"', project=project_id)
    if len(list_monitors) == 0:
        alerting_config = model_monitoring.EmailAlertConfig(
            user_emails=[email], enable_logging=True
        )
        # schedule config
        MONITOR_INTERVAL = 1
        schedule_config = model_monitoring.ScheduleConfig(
            monitor_interval=MONITOR_INTERVAL)
        # sampling strategy
        SAMPLE_RATE = 0.5
        logging_sampling_strategy = model_monitoring.RandomSampleConfig(
            sample_rate=SAMPLE_RATE)
        # drift config
        DRIFT_THRESHOLD_VALUE = 0.05
        DRIFT_THRESHOLDS = {
            "capital_gain": DRIFT_THRESHOLD_VALUE,
            "capital_loss": DRIFT_THRESHOLD_VALUE,
        }
        drift_config = model_monitoring.DriftDetectionConfig(
            drift_thresholds=DRIFT_THRESHOLDS)
        # Skew config
        DATASET_BQ_URI = bq_data_uri
        TARGET = "income_bracket"
        SKEW_THRESHOLD_VALUE = 0.5
        SKEW_THRESHOLDS = {
            "capital_gain": SKEW_THRESHOLD_VALUE,
            "capital_loss": SKEW_THRESHOLD_VALUE,
        }
        skew_config = model_monitoring.SkewDetectionConfig(
            data_source=DATASET_BQ_URI, skew_thresholds=SKEW_THRESHOLDS, target_field=TARGET
        )
        # objective config out of skew and drift configs
        objective_config = model_monitoring.ObjectiveConfig(
            skew_detection_config=skew_config,
            drift_detection_config=drift_config,
            explanation_config=None,
        )

        bqclient = bigquery.Client()
        table = bigquery.TableReference.from_string(DATASET_BQ_URI[5:])
        bq_table = bqclient.get_table(table)
        schema = bq_table.schema
        schemayaml = OrderedDict({
            "type": "object",
            "properties": {},
            "required": []
        })
        for feature in schema:
            if feature.name in ["income_bracket"]:
                continue
            if feature.field_type == "STRING":
                f_type = "string"
            else:
                f_type = "number"
            schemayaml['properties'][feature.name] = {"type": f_type}
            if feature.name not in ["fnlwgt", "education_num"]:
                schemayaml['required'].append(feature.name)

        with open("monitoring_schema.yaml", "w") as yaml_file:
            yaml.dump(schemayaml, yaml_file, default_flow_style=False)
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob("monitoring_schema.yaml")
        blob.upload_from_filename("monitoring_schema.yaml")

        monitoring_job = aiplatform.ModelDeploymentMonitoringJob.create(
            display_name=monitoring_name,
            project=project_id,
            location=region,
            endpoint=endpoint.metadata['resourceName'],
            logging_sampling_strategy=logging_sampling_strategy,
            schedule_config=schedule_config,
            alert_config=alerting_config,
            objective_configs=objective_config,
            analysis_instance_schema_uri=f"gs://{bucket_name}/monitoring_schema.yaml",
            encryption_spec_key_name=encryption,
        )
# create_monitoring = components.create_component_from_func(
#     create_monitoring_fun, base_image=Image)


@dsl.pipeline(name="census-income-pipeline")
def pipeline(
    create_bq_dataset_query: str,
    project: str,
    deployment_project: str,
    region: str,
    model_dir: str,
    bucket_name: str,
    monitoring_name: str,
    monitoring_email: str,
    encryption: str,
    service_account: str,
    prod_service_account: str,
    dataflow_subnet: str,
    train_data_url: str = TRAINING_URL,
    eval_data_url: str = EVAL_URL,
    bq_dataset: str = DATASET_ID,
    bq_train_table: str = TRAINING_TABLE_ID,
    bq_eval_table: str = EVAL_TABLE_ID,
    job_name: str = JOB_NAME,
    python_file_path: str = f'{BUCKET_URI}/src/ingest_pipeline.py',
    dataflow_temp_location: str = f'{BUCKET_URI}/temp_dataflow',
    runner: str = RUNNER,
    lr: float = 0.01,
    epochs: int = 5,
    batch_size: int = 32,
    base_train_dir: str = f'{BUCKET_URI}/training',
    tb_log_dir: str = f'{BUCKET_URI}/tblogs',
    deployment_image: str = "us-docker.pkg.dev/cloud-aiplatform/prediction/tf2-cpu.2-8:latest",
    deployed_model_name: str = 'income_bracket_predictor',
    endpoint_name: str = 'census_endpoint',
    min_nodes: int = 2,
    max_nodes: int = 4,
    traffic_split: int = 25,
    dataflow_sa: str = "",
):
    from google_cloud_pipeline_components.v1.bigquery import (
        BigqueryQueryJobOp)
    from google_cloud_pipeline_components.v1.dataflow import \
        DataflowPythonJobOp
    from google_cloud_pipeline_components.v1.wait_gcp_resources import \
        WaitGcpResourcesOp

    from google_cloud_pipeline_components.types import artifact_types
    from google_cloud_pipeline_components.v1.batch_predict_job import \
        ModelBatchPredictOp
    from google_cloud_pipeline_components.v1.model import ModelUploadOp
    from kfp.dsl import importer_node
    from google_cloud_pipeline_components.v1.endpoint import EndpointCreateOp, ModelDeployOp

    # create the dataset
    bq_dataset_op = BigqueryQueryJobOp(
        query=create_bq_dataset_query,
        project=project,
        location=region,
    )

    # instantiate dataflow args
    dataflow_args_train = build_dataflow_args(
        job_name=f"{job_name}train",
        url=train_data_url,
        bq_dataset=bq_dataset,
        bq_table=bq_train_table,
        runner=runner,
        bq_project=project,
        subnet=dataflow_subnet,
        dataflow_sa=dataflow_sa,
    ).after(bq_dataset_op)
    dataflow_args_eval = build_dataflow_args(
        job_name=f"{job_name}eval",
        url=eval_data_url,
        bq_dataset=bq_dataset,
        bq_table=bq_eval_table,
        runner=runner,
        bq_project=project,
        subnet=dataflow_subnet,
        dataflow_sa=dataflow_sa,
    ).after(bq_dataset_op)

    # run dataflow job
    dataflow_python_train_op = DataflowPythonJobOp(
        python_module_path=python_file_path,
        args=dataflow_args_train.output,
        project=project,
        location=region,
        temp_location=f"{dataflow_temp_location}/train",
    ).after(dataflow_args_train)
    dataflow_python_eval_op = DataflowPythonJobOp(
        python_module_path=python_file_path,
        args=dataflow_args_eval.output,
        project=project,
        location=region,
        temp_location=f"{dataflow_temp_location}/eval",
    ).after(dataflow_args_eval)

    dataflow_wait_train_op = WaitGcpResourcesOp(
        gcp_resources=dataflow_python_train_op.outputs["gcp_resources"]
    ).after(dataflow_python_train_op)
    dataflow_wait_eval_op = WaitGcpResourcesOp(
        gcp_resources=dataflow_python_eval_op.outputs["gcp_resources"]
    ).after(dataflow_python_eval_op)

    # create and train model
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

    custom_eval_task = custom_eval_model(
        model_dir=model_dir,
        project=project,
        table=bq_eval_table,
        dataset=bq_dataset,
        tb_log_dir=tb_log_dir,
        model=custom_training_task.outputs["model"],
        batch_size=batch_size,
    )
    custom_eval_task.after(custom_training_task)
    custom_eval_task.after(dataflow_wait_eval_op)
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
            service_account=prod_service_account
        ).after(custom_eval_task)

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


if __name__ == "__main__":
    compiler.Compiler().compile(pipeline_func=pipeline,
                                package_path="./common/vertex-ai-pipeline/pipeline_package.yaml")
