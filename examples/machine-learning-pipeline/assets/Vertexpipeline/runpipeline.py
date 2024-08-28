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
from datetime import datetime
from google.cloud import aiplatform
import os
# from pathlib import Path as path
# from urllib.parse import urlparse
# import os
# from six.moves import urllib
# import tempfile
# import numpy as np
# import pandas as pd
# import tensorflow as tf
# import tensorflow_hub as hub
# from google.cloud import aiplatform
# from google.cloud import bigquery
# from google.api_core.exceptions import GoogleAPIError
# from typing import NamedTuple


class vertex_ai_pipeline:
    def __init__(self,
                 # Replace the {non-prod-project_id} for your non-prod-project-id
                 PROJECT_ID: str = "{PRJ_N_MACHINE_LEARNING_ID}",
                 # Replace the {prod-project_id} for your prod-project-id
                 PROD_PROJECT_ID: str = "{PRJ_P_MACHINE_LEARNING_ID}",
                 REGION: str = "us-central1",
                 BUCKET_URI: str = "bucket_uri",
                 DATA_PATH: str = "data",
                 KFP_COMPONENTS_PATH: str = "components",
                 SRC: str = "src",
                 BUILD: str = "build",
                 TRAINING_FILE: str = 'adult.data.csv',
                 EVAL_FILE: str = 'adult.test.csv',
                 DATASET_ID: str = 'census_dataset',
                 TRAINING_TABLE_ID: str = 'census_train_table',
                 EVAL_TABLE_ID: str = 'census_eval_table',
                 RUNNER: str = "DataflowRunner",
                 # Replace the {PRJ_N_SHARED_RESTRICTED_ID} with your project_id
                 DATAFLOW_SUBNET: str = "https://www.googleapis.com/compute/v1/projects/{PRJ_N_SHARED_RESTRICTED_ID}/regions/us-central1/subnetworks/sb-n-shared-restricted-us-central1",
                 JOB_NAME: str = "census-ingest",
                 # Replace the {PRJ_N_MACHINE_LEARNING_NUMBER} with your prj_n_machine_learning_number 
                 SERVICE_ACCOUNT: str = "{PRJ_N_MACHINE_LEARNING_NUMBER}-compute@developer.gserviceaccount.com",
                 # Replace the {PRJ_P_MACHINE_LEARNING_NUMBER} with your prj_p_machine_learning_project_number
                 PROD_SERVICE_ACCOUNT: str = "{PRJ_P_MACHINE_LEARNING_NUMBER}-compute@developer.gserviceaccount.com",
                 # Replace the {DATAFLOW_SA} with your dataflow-sa from non-prod machine_learning_project
                 DATAFLOW_SA: str = "{DATAFLOW_SA}",
                 ):

        self.timestamp = datetime.now().strftime("%d_%H_%M_%S")
        self.PROJECT_ID = PROJECT_ID
        self.PROD_PROJECT_ID = PROD_PROJECT_ID
        self.REGION = REGION
        self.BUCKET_URI = BUCKET_URI
        self.DATA_PATH = DATA_PATH
        self.DATAFLOW_SA = DATAFLOW_SA

        DAGS_FOLDER = os.environ.get("DAGS_FOLDER", "./")
        COMMON_FOLDER = os.path.join(DAGS_FOLDER, "common")
        self.yaml_file_path = os.path.join(
            COMMON_FOLDER, "vertex-ai-pipeline/pipeline_package.yaml")

        self.KFP_COMPONENTS_PATH = KFP_COMPONENTS_PATH
        self.SRC = SRC
        self.BUILD = BUILD
        # Replace the {PRJ_C_MLARTIFACTS_ID} with the name of the image in artifact project of the common folder
        self.Image = "us-central1-docker.pkg.dev/{PRJ_C_MLARTIFACTS_ID}/c-publish-artifacts/vertexpipeline:v2"

        self.DATA_URL = f'{BUCKET_URI}/data'
        self.TRAINING_FILE = 'adult.data.csv'
        self.EVAL_FILE = 'adult.test.csv'
        self.TRAINING_URL = '%s/%s' % (self.DATA_URL, self.TRAINING_FILE)
        self.EVAL_URL = '%s/%s' % (self.DATA_URL, self.EVAL_FILE)
        self.DATASET_ID = 'census_dataset'
        self.TRAINING_TABLE_ID = 'census_train_table'
        self.EVAL_TABLE_ID = 'census_eval_table'
        self.RUNNER = "DataflowRunner"
        self.JOB_NAME = "census-ingest"
        self.SERVICE_ACCOUNT = SERVICE_ACCOUNT
        self.PROD_SERVICE_ACCOUNT = PROD_SERVICE_ACCOUNT

        self.create_bq_dataset_query = f"""
        CREATE SCHEMA IF NOT EXISTS {self.DATASET_ID}
        """
        self.data_config = {
            "train_data_url": self.TRAINING_URL,
            "eval_data_url": self.EVAL_URL,
            "bq_dataset": self.DATASET_ID,
            "bq_train_table": TRAINING_TABLE_ID,
            "bq_eval_table": EVAL_TABLE_ID,
        }

        self.dataflow_config = {
            "job_name": JOB_NAME,
            "python_file_path": f'{BUCKET_URI}/src/ingest_pipeline.py',
            "temp_location": f'{BUCKET_URI}/temp_dataflow',
            "runner": RUNNER,
            "subnet": DATAFLOW_SUBNET
        }
        self.train_config = {
            'lr': 0.01,
            'epochs': 5,
            'base_train_dir': f'{BUCKET_URI}/training',
            'tb_log_dir': f'{BUCKET_URI}/tblogs',
        }

        self.deployment_config = {
            'image': 'us-docker.pkg.dev/cloud-aiplatform/prediction/tf2-cpu.2-8:latest',
            'model_name': "income_bracket_predictor_prod",
            'endpoint_name': "census_income_endpoint_prod",
            'min_nodes': 2,
            'max_nodes': 4,
            'deployment_project': self.PROD_PROJECT_ID,
            # Replace encryption with the name of the kms key in the kms project of the prod folder and the prod kms ID project
            "encryption": 'projects/{PRJ_P_KMS_ID}/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-p-mlmachine-learning',
            "service_account": self.SERVICE_ACCOUNT,
            "prod_service_account": self.PROD_SERVICE_ACCOUNT
        }

        self.monitoring_config = {
            # Replace the email with your email address
            'email': '{YOUR-EMAIL@YOUR-COMPANY.COM}',
            'name': 'census_monitoring'
        }

        self.pipelineroot = f'{BUCKET_URI}/pipelineroot'

    def execute(self):
        pipeline = aiplatform.PipelineJob(
            display_name=f"census_income_{self.timestamp}",
            template_path=self.yaml_file_path,
            pipeline_root=self.pipelineroot,
            # Replace encryption with the name of the kms key in the kms project of the non-prod folder and also de non-prod KMS project ID
            encryption_spec_key_name='projects/{PRJ_N_KMS_ID}/locations/us-central1/keyRings/sample-keyring/cryptoKeys/prj-n-mlmachine-learning',
            parameter_values={
                "create_bq_dataset_query": self.create_bq_dataset_query,
                "bq_dataset": self.data_config['bq_dataset'],
                "bq_train_table": self.data_config['bq_train_table'],
                "bq_eval_table": self.data_config['bq_eval_table'],
                "job_name": self.dataflow_config['job_name'],
                "train_data_url": self.data_config['train_data_url'],
                "eval_data_url": self.data_config['eval_data_url'],
                "python_file_path": self.dataflow_config['python_file_path'],
                "dataflow_temp_location": self.dataflow_config['temp_location'],
                "runner": self.dataflow_config['runner'],
                "dataflow_subnet": self.dataflow_config['subnet'],
                "project": self.PROJECT_ID,
                "region": self.REGION,
                "model_dir": f"{self.BUCKET_URI}",
                "bucket_name": self.BUCKET_URI[5:],
                "epochs": self.train_config['epochs'],
                "lr": self.train_config['lr'],
                "base_train_dir": self.train_config['base_train_dir'],
                "tb_log_dir": self.train_config['tb_log_dir'],
                "deployment_image": self.deployment_config['image'],
                "deployed_model_name": self.deployment_config["model_name"],
                "endpoint_name": self.deployment_config["endpoint_name"],
                "min_nodes": self.deployment_config["min_nodes"],
                "max_nodes": self.deployment_config["max_nodes"],
                "deployment_project": self.deployment_config["deployment_project"],
                "encryption": self.deployment_config.get("encryption"),
                "service_account": self.deployment_config["service_account"],
                "prod_service_account": self.deployment_config["prod_service_account"],
                "monitoring_name": self.monitoring_config['name'],
                "monitoring_email": self.monitoring_config['email'],
                "dataflow_sa": self.DATAFLOW_SA,
            },
            enable_caching=False,
        )

        return pipeline.run(service_account=self.SERVICE_ACCOUNT)


if __name__ == "__main__":
    pipeline = vertex_ai_pipeline(
        # Replace with your Machine Learning non-prod project Id
        PROJECT_ID="{PRJ_N_MACHINE_LEARNING_ID}", \
        # Replace with your Machine Learning prod project ID
        PROD_PROJECT_ID='{PRJ_P_MACHINE_LEARNING_ID}', \
        REGION="us-central1", \
        # Replace with your bucket in non-prod ID
        BUCKET_URI="gs://{NON_PROD_BUCKET_NAME}", \
        DATA_PATH="data", \
        KFP_COMPONENTS_PATH="components", \
        SRC="src", \
        BUILD="build", \
        TRAINING_FILE='adult.data.csv', \
        EVAL_FILE='adult.test.csv', \
        DATASET_ID='census_dataset', \
        TRAINING_TABLE_ID='census_train_table', \
        EVAL_TABLE_ID='census_eval_table', \
        RUNNER="DataflowRunner", \
        # Replace with the name of the subnet in your shared-restricted project in the non-prod environment
        DATAFLOW_SUBNET="https://www.googleapis.com/compute/v1/projects/{PRJ_N_SHARED_RESTRICTED_ID}/regions/us-central1/subnetworks/sb-n-shared-restricted-us-central1", \
        JOB_NAME="census-ingest", \
        # Replace the {PRJ_N_MACHINE_LEARNING_NUMBER} with your Non-production Machine Learning Project Number
        SERVICE_ACCOUNT="{PRJ_N_MACHINE_LEARNING_NUMBER}-compute@developer.gserviceaccount.com", \
        # Replace the {PRJ_P_MACHINE_LEARNING_NUMBER} with your Production Machine Learning Project Number
        PROD_SERVICE_ACCOUNT="{PRJ_P_MACHINE_LEARNING_NUMBER}-compute@developer.gserviceaccount.com",
        # Replace the {PRJ_N_MACHINE_LEARNING_ID} with your Non-production Machine Learning Project ID
        DATAFLOW_SA="dataflow-sa@{PRJ_N_MACHINE_LEARNING_ID}.iam.gserviceaccount.com",
    )

    pipeline.execute()
