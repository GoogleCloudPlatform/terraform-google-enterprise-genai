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
import argparse
from typing import Optional, Dict, List, Any
from google.cloud import aiplatform
from google.cloud.aiplatform.metadata.schema.system import artifact_schema
from google.cloud.aiplatform.metadata.schema.system import execution_schema
from common.components.utils import create_artifact_sample, create_execution_sample, list_artifact_sample




def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', dest='project')
    parser.add_argument('--bq-table', dest='table_id')
    parser.add_argument('--bq-dataset', dest='dataset_id')
    parser.add_argument('--tb-log-dir', dest='tb_log_dir')
    parser.add_argument('--model-dir', dest='model_dir')
    parser.add_argument('--batch_size', dest='batch_size')
    args = parser.parse_args()
    return args

# evaluation component
def custom_eval_model(
    model_dir: str,
    project: str,
    table: str,
    dataset: str,
    tb_log_dir: str,
    batch_size: int = 32,
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
        trimmed_dict = { column:
                      (tf.strings.strip(tensor) if tensor.dtype == 'string' else tensor)
                      for (column,tensor) in row_dict.items()
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
    keras_model = tf.keras.models.load_model(model_dir)
    tensorboard = tf.keras.callbacks.TensorBoard(log_dir=tb_log_dir)
    loss, accuracy = keras_model.evaluate(eval_ds, callbacks=[tensorboard])

    metric = create_artifact_sample(
        project=project,
        location='us-central1',
        display_name='composer_eval_metric',
        description='Eval metrics produced from composer dag',
        metadata={'accuracy': accuracy}
    )

    model_artifact = list_artifact_sample(project=project,
                     location='us-central1',
                     display_name_filter="display_name=\"composer_trained_census_model\"",
                     order_by="LAST_UPDATE_TIME desc")[0]

    data_artifact = list_artifact_sample(project=project,
                     location='us-central1',
                     display_name_filter="display_name=\"composer_training_data\"",
                     order_by="LAST_UPDATE_TIME desc")[0]

    execution_event = create_execution_sample(
        display_name='evaluation_execution_composer',
        input_artifacts=[data_artifact, model_artifact],
        output_artifacts=[metric],
        project=project,
        location='us-central1',
        description='execution representing model evaluation via composer',
    )

    if accuracy > 0.8:
        dep_decision = True
    else:
        dep_decision = False
    return dep_decision




if __name__=="__main__":
    args = get_args()
    custom_eval_model(
    project=args.project,
    table=args.table_id,
    dataset=args.dataset_id,
    tb_log_dir=args.tb_log_dir,
    model_dir=args.model_dir,
    batch_size=args.batch_size,
)
