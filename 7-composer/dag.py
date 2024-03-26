from datetime import timedelta, datetime
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateEmptyDatasetOperator
from airflow.providers.apache.beam.operators.beam import BeamRunPythonPipelineOperator
from airflow.providers.google.cloud.sensors.dataflow import DataflowJobStatusSensor
from airflow.providers.google.cloud.hooks.dataflow import DataflowJobStatus
from airflow.operators.python import PythonOperator, ShortCircuitOperator
from airflow.decorators import task

from common.components.training import custom_train_model
from common.components.eval import custom_eval_model
from common.components.deployment import deploy_model
from common.components.monitoring import create_monitoring

REGION               = "us-central1"
BUCKET_URI           = "gs://testairflowpipe"
PROJECT_ID           = "majid-test-407120"
DATASET_ID           = 'census_dataset_composer'
TRAINING_TABLE_ID    = 'census_train_table_composer'
EVAL_TABLE_ID        = 'census_eval_table_composer'
RUNNER               = "DataflowRunner"
REGION               = "us-central1"
JOB_NAME             = "census-ingest-composer"
default_kms_key_name = "projects/prj-d-kms-cgvl/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-d-bu3machine-learning"
deployment_image     = "us-docker.pkg.dev/cloud-aiplatform/prediction/tf2-cpu.2-8:latest"
service_account      = "728034955955-compute@developer.gserviceaccount.com"
prod_service_account = "728034955955-compute@developer.gserviceaccount.com"

default_args = {
    'owner'           : 'airflow',
    'depends_on_past' : False,
    'start_date'      : datetime(2023, 1, 1),
    'email_on_failure': False,
    'email_on_retry'  : False,
    'retries'         : 1,
    'retry_delay'     : timedelta(minutes=5),
}

dag = DAG(
    'census_dag',
    default_args=default_args,
    description='census pipeline built with airlfow',
    schedule_interval=timedelta(days=1),  # Set the schedule interval (e.g., daily)
    catchup=False,
    start_date=default_args['start_date']
)

bqOperator = BigQueryCreateEmptyDatasetOperator(
    task_id = "bqtask",
    dataset_id=DATASET_ID,
    project_id=PROJECT_ID,
    location=REGION,
    dataset_reference={"defaultEncryptionConfiguration":{"kmsKeyName": default_kms_key_name}},
    dag=dag,
)

traindata_ingest_op = BeamRunPythonPipelineOperator(
    runner="DataflowRunner",
    task_id="ingest_census_train_data_async",
    py_file=f"{BUCKET_URI}/dataflow_src/ingest_pipeline.py",
    py_options=[],
    pipeline_options={
        "url": f"{BUCKET_URI}/data/adult.data.csv",
        "bq-dataset": DATASET_ID,
        "bq-table": TRAINING_TABLE_ID,
        "bq-project": PROJECT_ID,
        "output": BUCKET_URI,
        "tempLocation": f"{BUCKET_URI}/dataflow_temp_train",
        "stagingLocation": f"{BUCKET_URI}/dataflow_stage_train"
    },
    py_requirements=["apache-beam[gcp]==2.52.0"],
    py_interpreter="python3",
    py_system_site_packages=False,
    dataflow_config={
        "job_name": "{{task.task_id}}",
        "location": REGION,
        "wait_until_finished": False,
    },
    dag=dag
)
wait_for_traindata_ingest_op = DataflowJobStatusSensor(
    task_id="wait-for-traindata-ingest",
    job_id="{{task_instance.xcom_pull('ingest_census_train_data_async')['dataflow_job_id']}}",
    expected_statuses={DataflowJobStatus.JOB_STATE_DONE},
    project_id=PROJECT_ID,
    location="us-central1",
    dag=dag
)


evaldata_ingest_op = BeamRunPythonPipelineOperator(
    runner="DataflowRunner",
    task_id="ingest_census_eval_data_async",
    py_file=f"{BUCKET_URI}/dataflow_src/ingest_pipeline.py",
    py_options=[],
    pipeline_options={
        "url": f"{BUCKET_URI}/data/adult.test.csv",
        "bq-dataset": DATASET_ID,
        "bq-table": EVAL_TABLE_ID,
        "bq-project": PROJECT_ID,
        "output": BUCKET_URI,
        "tempLocation": f"{BUCKET_URI}/dataflow_temp_test",
        "stagingLocation": f"{BUCKET_URI}/dataflow_stage_test"
    },
    py_requirements=["apache-beam[gcp]==2.52.0"],
    py_interpreter="python3",
    py_system_site_packages=False,
    dataflow_config={
        "job_name": "{{task.task_id}}",
        "location": REGION,
        "wait_until_finished": False,
    },
    dag=dag
)
wait_for_evaldata_ingest_op = DataflowJobStatusSensor(
    task_id="wait-for-evaldata-ingest",
    job_id="{{task_instance.xcom_pull('ingest_census_eval_data_async')['dataflow_job_id']}}",
    expected_statuses={DataflowJobStatus.JOB_STATE_DONE},
    project_id=PROJECT_ID,
    location="us-central1",
    dag=dag
)



training_op = PythonOperator(
    task_id='model_training',
    python_callable=custom_train_model,
    op_kwargs={'project': PROJECT_ID, 
               'table':TRAINING_TABLE_ID, 
               'dataset': DATASET_ID, 
               'tb_log_dir': f"{BUCKET_URI}/tblogs", 
               'model_dir': f"{BUCKET_URI}/modelartifact",},
    dag=dag
)

eval_op = ShortCircuitOperator(
    task_id='model_evaluation',
    provide_context=True,
    python_callable=custom_eval_model,
    op_kwargs={
               'project': PROJECT_ID, 
               'table':TRAINING_TABLE_ID, 
               'dataset': DATASET_ID, 
               'tb_log_dir': f"{BUCKET_URI}/tblogs", 
               'model_dir': f"{BUCKET_URI}/modelartifact",},
    dag=dag
)



deploy_op = PythonOperator(
    task_id='model_deployment',
    python_callable=deploy_model,
    op_kwargs={
        'serving_container_image_uri': deployment_image,
        'model_name':'composer_census_model',
        'model_dir': f"{BUCKET_URI}/modelartifact",
        'endpoint_name': 'composer_census_endpoint',
        'project_id': PROJECT_ID,
        'region': REGION,
        'split': 25,
        'min_nodes': 1,
        'max_nodes': 2,
        'service_account': prod_service_account,
        'encryption_keyname': default_kms_key_name,
    },
    dag=dag
)


monitoring_op = PythonOperator(
    task_id='model_monitoring',
    python_callable=create_monitoring,
    op_kwargs={
        'monitoring_name': 'composer_monitor_census',
        'project_id': PROJECT_ID,
        'region': REGION,
        'bq_data_uri': f"bq://{PROJECT_ID}.{DATASET_ID}.{TRAINING_TABLE_ID}",
        'bucket_name': BUCKET_URI[5:],
        'email': 'majid.alikhani@badal.io',
        'encryption_keyname': default_kms_key_name,
        'service_account': service_account,
    },
    dag=dag
)

bqOperator >> traindata_ingest_op >> wait_for_traindata_ingest_op
bqOperator >> evaldata_ingest_op >> wait_for_evaldata_ingest_op
[wait_for_traindata_ingest_op, wait_for_evaldata_ingest_op] >> training_op >> eval_op >> deploy_op >> monitoring_op