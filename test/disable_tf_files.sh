#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function networks(){

    # disable access_context.auto.tfvars in main module
    mv 3-networks-dual-svpc/envs/development/access_context.auto.tfvars  3-networks-dual-svpc/envs/development/access_context.auto.tfvars.disabled
    mv 3-networks-dual-svpc/envs/non-production/access_context.auto.tfvars  3-networks-dual-svpc/envs/non-production/access_context.auto.tfvars.disabled
    mv 3-networks-dual-svpc/envs/production/access_context.auto.tfvars  3-networks-dual-svpc/envs/production/access_context.auto.tfvars.disabled

    # disable common.auto.tfvars in main module
    mv 3-networks-dual-svpc/envs/development/common.auto.tfvars 3-networks-dual-svpc/envs/development/common.auto.tfvars.disabled
    mv 3-networks-dual-svpc/envs/non-production/common.auto.tfvars  3-networks-dual-svpc/envs/non-production/common.auto.tfvars.disabled
    mv 3-networks-dual-svpc/envs/production/common.auto.tfvars  3-networks-dual-svpc/envs/production/common.auto.tfvars.disabled
}

function shared(){

    # disable access_context.auto.tfvars in main module
    mv 3-networks-dual-svpc/envs/shared/access_context.auto.tfvars 3-networks-dual-svpc/envs/shared/access_context.auto.tfvars.disabled

    # disable common.auto.tfvars in main module
    mv 3-networks-dual-svpc/envs/shared/common.auto.tfvars  3-networks-dual-svpc/envs/shared/common.auto.tfvars.disabled

    # disable shared.auto.tfvars in main module
    mv 3-networks-dual-svpc/envs/shared/shared.auto.tfvars  3-networks-dual-svpc/envs/shared/shared.auto.tfvars.disabled
}

function projectsshared(){
    # disable shared.auto.tfvars
    mv 4-projects/ml_business_unit/shared/shared.auto.tfvars  4-projects/ml_business_unit/shared/shared.auto.tfvars.disabled

    # disable common.auto.tfvars
    mv 4-projects/ml_business_unit/shared/common.auto.tfvars  4-projects/ml_business_unit/shared/common.auto.tfvars.disabled
}

function projects(){
    # disable ENVS.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/development.auto.tfvars 4-projects/ml_business_unit/development/development.auto.tfvars.disabled
    mv 4-projects/ml_business_unit/non-production/non-production.auto.tfvars  4-projects/ml_business_unit/non-production/non-production.auto.tfvars.disabled
    mv 4-projects/ml_business_unit/production/production.auto.tfvars 4-projects/ml_business_unit/production/production.auto.tfvars.disabled

    # disable common.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/common.auto.tfvars 4-projects/ml_business_unit/development/common.auto.tfvars.disabled
    mv 4-projects/ml_business_unit/non-production/common.auto.tfvars  4-projects/ml_business_unit/non-production/common.auto.tfvars.disabled
    mv 4-projects/ml_business_unit/production/common.auto.tfvars 4-projects/ml_business_unit/production/common.auto.tfvars.disabled
}

function appinfra(){
    # disable common.auto.tfvars in main module
    mv 5-app-infra/projects/artifact-publish/ml_business_unit/shared/common.auto.tfvars 5-app-infra/projects/artifact-publish/ml_business_unit/shared/common.auto.tfvars.disabled
    mv 5-app-infra/projects/service-catalog/ml_business_unit/shared/common.auto.tfvars  5-app-infra/projects/service-catalog/ml_business_unit/shared/common.auto.tfvars.disabled
}


# parse args
for arg in "$@"
do
  case $arg in
    -n|--networks)
      networks
      shift
      ;;
    -s|--shared)
      shared
      shift
      ;;
    -a|--appinfra)
      appinfra
      shift
      ;;
    -d|--projectsshared)
      projectsshared
      shift
      ;;
    -p|--projects)
      projects
      shift
      ;;
      *) # end argument parsing
      shift
      ;;
  esac
done
