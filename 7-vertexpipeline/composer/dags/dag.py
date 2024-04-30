import airflow
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import timedelta
import os

DAGS_FOLDER = os.environ.get("DAGS_FOLDER")
COMMON_FOLDER = os.path.join(DAGS_FOLDER, "common")
file_path = os.path.join(COMMON_FOLDER, "vertex-ai-pipeline/runpipeline.py")

default_args = {
    'start_date': airflow.utils.dates.days_ago(0),
    'retries': 2,
    'retry_delay': timedelta(minutes=10)
}

dag = DAG(
    'vertex-ai-pipeline-test',
    default_args=default_args,
    description='Vertex AI Pipeline test',
    schedule_interval='0 0 1 * *',
    max_active_runs=1,
    catchup=False,
    dagrun_timeout=timedelta(minutes=60),
)

def run_pipeline_function_callable():
    # Import the module and call the function
    import importlib.util
    spec = importlib.util.spec_from_file_location("runpipeline", file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    # Create an instance of the class
    pipeline_instance = module.vertex_ai_pipeline()

    # Call the execute method on the instance
    pipeline_instance.execute()

t1 = PythonOperator(
    task_id='vertexaipipelinetest',
    python_callable=run_pipeline_function_callable,
    dag=dag
)
