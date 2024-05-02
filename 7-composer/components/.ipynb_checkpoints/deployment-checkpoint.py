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


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--serving-container', dest='serving_container')
    parser.add_argument('--model-name', dest='model_name')
    parser.add_argument('--model-dir', dest='model_dir')
    parser.add_argument('--endpoint-name', dest='endpoint_name')
    parser.add_argument('--project', dest='project')
    parser.add_argument('--region', dest='region')
    parser.add_argument('--split', dest='split')
    parser.add_argument('--min-nodes', dest='min_nodes')
    parser.add_argument('--max-nodes', dest='max_nodes')
    parser.add_argument('--service-account', dest='service_account')
    args = parser.parse_args()
    return args


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
            endpoint = endpoints[0] # most recently created
        else:
            endpoint = aiplatform.Endpoint.create(
                display_name=endpoint_name,
                project=project_id,
                location=region
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
            )
        else:
            model_upload = aiplatform.Model.upload(
                    display_name=model_name,
                    artifact_uri=model_dir,
                    serving_container_image_uri=serving_container_image_uri,
                    location=region,
            )
        return model_upload

    uploaded_model = upload_model()

    # Save data to the output params
    vertex_model.uri = uploaded_model.resource_name
    def deploy_to_endpoint(model, endpoint):
        deployed_models = endpoint.list_models()
        if len(deployed_models) > 0:
            latest_model_id = deployed_models[-1].id
            print("your objects properties:", deployed_models[0].create_time.__dir__())
            model_deploy = uploaded_model.deploy(
                # machine_type="n1-standard-4",
                endpoint=endpoint,
                traffic_split={"0": 25, latest_model_id: 75},
                deployed_model_display_name=model_name,
                min_replica_count=min_nodes,
                max_replica_count=max_nodes,
                # service_account="compute default"
            )
        else:
            model_deploy = uploaded_model.deploy(
            # machine_type="n1-standard-4",
            endpoint=endpoint,
            traffic_split={"0": 100},
            min_replica_count=min_nodes,
            max_replica_count=max_nodes,
            deployed_model_display_name=model_name,
            # service_account="compute default"
        )
        return model_deploy.resource_name

    vertex_endpoint.uri = deploy_to_endpoint(vertex_model, endpoint)
    vertex_endpoint.metadata['resourceName']=endpoint.resource_name




if __name__=="__main__":
    args = get_args()
    deploy_model(
        serving_container_image_uri=args.serving_container,
        model_name=args.model_name,
        model_dir=args.model_dir,
        endpoint_name=args.endpoint_name,
        project_id=args.project_id,
        region=args.region,
        split=args.split,
        min_nodes=args.min_nodes,
        max_nodes=args.max_nodes,
        service_account=args.service_account,
)
