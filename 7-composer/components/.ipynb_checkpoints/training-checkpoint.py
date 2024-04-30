import argparse
from typing import Optional, Dict, List
from google.cloud import aiplatform
from google.cloud.aiplatform.metadata.schema.system import artifact_schema
from google.cloud.aiplatform.metadata.schema.system import execution_schema

def create_artifact_sample(
    project: str,
    location: str,
    uri: Optional[str] = None,
    artifact_id: Optional[str] = None,
    display_name: Optional[str] = None,
    schema_version: Optional[str] = None,
    description: Optional[str] = None,
    metadata: Optional[Dict] = None,
):
    system_artifact_schema = artifact_schema.Artifact(
        uri=uri,
        artifact_id=artifact_id,
        display_name=display_name,
        schema_version=schema_version,
        description=description,
        metadata=metadata,
    )
    return system_artifact_schema.create(project=project, location=location,)

def create_execution_sample(
    display_name: str,
    input_artifacts: List[aiplatform.Artifact],
    output_artifacts: List[aiplatform.Artifact],
    project: str,
    location: str,
    execution_id: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    schema_version: Optional[str] = None,
    description: Optional[str] = None,
):
    aiplatform.init(project=project, location=location)

    with execution_schema.ContainerExecution(
        display_name=display_name,
        execution_id=execution_id,
        metadata=metadata,
        schema_version=schema_version,
        description=description,
    ).create() as execution:
        execution.assign_input_artifacts(input_artifacts)
        execution.assign_output_artifacts(output_artifacts)
        return execution


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', dest='project')
    parser.add_argument('--bq-table', dest='table_id')
    parser.add_argument('--bq-dataset', dest='dataset_id')
    parser.add_argument('--tb-log-dir', dest='tb_log_dir')
    parser.add_argument('--epochs', dest='epochs')
    parser.add_argument('--batch_size', dest='batch_size')
    parser.add_argument('--lr', dest='lr')
    args = parser.parse_args()
    return args



def custom_train_model(
    project: str,
    table: str,
    dataset: str,
    tb_log_dir: str,
    model: Output[Model],
    epochs: int = 5,
    batch_size: int = 32,
    lr: float = 0.01, # not used here but can be passed to an optimizer
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

    training_ds = read_bigquery(table).shuffle(10000).batch(batch_size)



    feature_columns = []
    def get_categorical_feature_values(column):
        query = 'SELECT DISTINCT TRIM({}) FROM `{}`.{}.{}'.format(column, project, dataset, table)
        client = bigquery.Client(project=project)
        dataset_ref = client.dataset(dataset)
        job_config = bigquery.QueryJobConfig()
        query_job = client.query(query, job_config=job_config)
        result = query_job.to_dataframe()
        return result.values[:,0]

    # numeric cols
    for header in ['capital_gain', 'capital_loss', 'hours_per_week']:
        feature_columns.append(feature_column.numeric_column(header))

    # categorical cols
    for header in ['workclass', 'marital_status', 'occupation', 'relationship',
                   'race', 'native_country', 'education']:
        categorical_feature = feature_column.categorical_column_with_vocabulary_list(
            header, get_categorical_feature_values(header))
        categorical_feature_one_hot = feature_column.indicator_column(categorical_feature)
        feature_columns.append(categorical_feature_one_hot)

    # bucketized cols
    age = feature_column.numeric_column('age')
    age_buckets = feature_column.bucketized_column(age, boundaries=[18, 25, 30, 35, 40, 45, 50, 55, 60, 65])
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


if __name__=="__main__":
    args = get_args()
    custom_train_model(
    project=args.project,
    table=args.table_id,
    dataset=args.dataset_id,
    tb_log_dir=args.tb_log_dir,
    epochs=args.epochs,
    batch_size=args.batch_size,
    lr=args.lr, # not used here but can be passed to an optimizer
)