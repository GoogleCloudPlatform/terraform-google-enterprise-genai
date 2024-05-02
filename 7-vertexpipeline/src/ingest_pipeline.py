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
from __future__ import absolute_import
import logging
import argparse
import apache_beam as beam
from apache_beam.io import ReadFromText, ReadAllFromText
from apache_beam.dataframe.io import read_csv
from apache_beam.io.gcp.bigquery import WriteToBigQuery
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io.gcp.internal.clients import bigquery
from apache_beam.options.pipeline_options import SetupOptions


def get_bigquery_schema():
    """
    A function to get the BigQuery schema.
    Returns:
        A list of BigQuery schema.
    """

    table_schema = bigquery.TableSchema()
    columns = (('age', 'FLOAT64', 'nullable'),
               ('workclass', 'STRING', 'nullable'),
               ('fnlwgt', 'FLOAT64', 'nullable'),
               ('education', 'STRING', 'nullable'),
               ('education_num', 'FLOAT64', 'nullable'),
               ('marital_status', 'STRING', 'nullable'),
               ('occupation', 'STRING', 'nullable'),
               ("relationship", "STRING", 'nullable'),
               ("race", "STRING", 'nullable'),
               ("gender", "STRING", 'nullable'),
               ("capital_gain", "FLOAT64", 'nullable'),
               ("capital_loss", "FLOAT64", 'nullable'),
               ("hours_per_week", "FLOAT64", 'nullable'),
               ("native_country", "STRING", 'nullable'),
               ("income_bracket", "STRING", 'nullable')
               )

    for column in columns:
        column_schema = bigquery.TableFieldSchema()
        column_schema.name = column[0]
        column_schema.type = column[1]
        column_schema.mode = column[2]
        table_schema.fields.append(column_schema)

    return table_schema


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', dest='url', default="BUCKET_URI/data/adult.data.csv",
                        help='url of the data to be downloaded')
    parser.add_argument('--bq-dataset', dest='dataset_id', required=False,
                        default='census_dataset', help='Dataset name used in BigQuery.')
    parser.add_argument('--bq-table', dest='table_id', required=False,
                        default='census_train_table', help='Table name used in BigQuery.')
    parser.add_argument('--bq-project', dest='project_id', required=False,
                        default='majid-test-407120', help='project id')
    args, pipeline_args = parser.parse_known_args()
    return args, pipeline_args


def transform(line):
    values = line.split(",")
    d = {}
    fields = ["age", "workclass", "fnlwgt", "education", "education_num",
              "marital_status", "occupation", "relationship", "race", "gender",
              "capital_gain", "capital_loss", "hours_per_week", "native_country", "income_bracket"]
    for i in range(len(fields)):
        d[fields[i]] = values[i].strip()
    return d


def load_data_into_bigquery(args, pipeline_args):
    options = PipelineOptions(pipeline_args)
    options.view_as(SetupOptions).save_main_session = True
    p = beam.Pipeline(options=options)

    (p
     | 'Create PCollection' >> beam.Create([args.url])
     | 'ReadFromText' >> ReadAllFromText(skip_header_lines=1)
     | 'string to bq row' >> beam.Map(lambda s: transform(s))
     | 'WriteToBigQuery' >> WriteToBigQuery(
         table=args.table_id,
         dataset=args.dataset_id,
         project=args.project_id,
         schema=get_bigquery_schema(),
         create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
         write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
     )
     )

    job = p.run()
    if options.get_all_options()['runner'] == 'DirectRunner':
        job.wait_until_finish()


if __name__ == '__main__':
    args, pipeline_args = get_args()
    logging.getLogger().setLevel(logging.INFO)
    load_data_into_bigquery(args, pipeline_args)
