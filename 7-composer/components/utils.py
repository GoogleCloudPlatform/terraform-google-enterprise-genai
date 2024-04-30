from google.cloud.aiplatform.metadata.schema.system import artifact_schema
from google.cloud.aiplatform.metadata.schema.system import execution_schema
from google.cloud import aiplatform
from typing import Optional, Dict, List, Any

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


def list_artifact_sample(
    project: str,
    location: str,
    display_name_filter: Optional[str] = "display_name=\"my_model_*\"",
    create_date_filter: Optional[str] = "create_time>\"2022-06-11\"",
    order_by: Optional[str] = "LAST_UPDATE_TIME desc",
):
    aiplatform.init(project=project, location=location)

    combined_filters = f"{display_name_filter} AND {create_date_filter}"
    return aiplatform.Artifact.list(
        filter=combined_filters,
        order_by=order_by,
    )
