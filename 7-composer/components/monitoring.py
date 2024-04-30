import argparse
from common.components.utils import create_artifact_sample, create_execution_sample, list_artifact_sample

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--monitoring-name', dest='monitoring_name')
    parser.add_argument('--endpoint-name', dest='endpoint_name')
    parser.add_argument('--project', dest='project')
    parser.add_argument('--region', dest='region')
    parser.add_argument('--bq-data-uri', dest='bq_data_uri')
    parser.add_argument('--bucket-name', dest='bucket_name')
    parser.add_argument('--email', dest='email')
    parser.add_argument('--service-account', dest='service_account')
    args = parser.parse_args()
    return args


def create_monitoring(
    monitoring_name: str,
    project_id: str,
    region: str,
    # endpoint: Input[Model],
    bq_data_uri: str,
    bucket_name: str,
    email: str,
    encryption_keyname: str,
    service_account: str,
):
    from google.cloud.aiplatform import model_monitoring
    from google.cloud import aiplatform
    from google.cloud import bigquery
    from google.cloud import storage
    from collections import OrderedDict
    import time
    import yaml
    def ordered_dict_representer(self, value):  # can be a lambda if that's what you prefer
        return self.represent_mapping('tag:yaml.org,2002:map', value.items())
    yaml.add_representer(OrderedDict, ordered_dict_representer)

    aiplatform.init(service_account=service_account)
    list_monitors = aiplatform.ModelDeploymentMonitoringJob.list(filter=f'state="JOB_STATE_SUCCEEDED" AND display_name="{monitoring_name}"', project=project_id)
    if len(list_monitors) == 0:
        alerting_config = model_monitoring.EmailAlertConfig(
            user_emails=[email], enable_logging=True
        )
        # schedule config
        MONITOR_INTERVAL = 1
        schedule_config = model_monitoring.ScheduleConfig(monitor_interval=MONITOR_INTERVAL)
        # sampling strategy
        SAMPLE_RATE = 0.5
        logging_sampling_strategy = model_monitoring.RandomSampleConfig(sample_rate=SAMPLE_RATE)
        # drift config
        DRIFT_THRESHOLD_VALUE = 0.05
        DRIFT_THRESHOLDS = {
            "capital_gain": DRIFT_THRESHOLD_VALUE,
            "capital_loss": DRIFT_THRESHOLD_VALUE,
        }
        drift_config = model_monitoring.DriftDetectionConfig(drift_thresholds=DRIFT_THRESHOLDS)
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
        endpoint_artifact = list_artifact_sample(
            project=project_id,
            location=region,
            display_name_filter="display_name=\"composer_modelendpoint\"",
            order_by="LAST_UPDATE_TIME desc",
        )[0]
        monitoring_job = aiplatform.ModelDeploymentMonitoringJob.create(
            display_name=monitoring_name,
            project=project_id,
            location=region,
            endpoint=endpoint_artifact.metadata['resource_name'],
            logging_sampling_strategy=logging_sampling_strategy,
            schedule_config=schedule_config,
            alert_config=alerting_config,
            objective_configs=objective_config,
            analysis_instance_schema_uri=f"gs://{bucket_name}/monitoring_schema.yaml",
            encryption_spec_key_name=encryption_keyname,
        )

if __name__=="__main__":
    args = get_args()
    create_monitoring(
        monitoring_name=args.monitoring_name,
        project_id=args.project,
        region=args.region,
        bq_data_uri=args.bq_data_uri,
        bucket_name=args.bucket_name,
        email=args.email,
        service_account=args.service_account,
)
