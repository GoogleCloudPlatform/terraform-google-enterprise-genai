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

function org(){
    # restore backend configs in main module
    mv 1-org/envs/shared/backend.tf.disabled  1-org/envs/shared/backend.tf
}

function envs(){
    # restore backend configs in main module
    mv 2-environments/envs/development/backend.tf.disabled  2-environments/envs/development/backend.tf
    mv 2-environments/envs/nonproduction/backend.tf.disabled  2-environments/envs/nonproduction/backend.tf
    mv 2-environments/envs/production/backend.tf.disabled  2-environments/envs/production/backend.tf
}

function networks(){
    # restore backend configs in main module
    mv 3-networks-svpc/envs/development/backend.tf.disabled  3-networks-svpc/envs/development/backend.tf
    mv 3-networks-svpc/envs/nonproduction/backend.tf.disabled  3-networks-svpc/envs/nonproduction/backend.tf
    mv 3-networks-svpc/envs/production/backend.tf.disabled  3-networks-svpc/envs/production/backend.tf

    # restore access_context.auto.tfvars in main module
    mv 3-networks-svpc/envs/development/access_context.auto.tfvars.disabled  3-networks-svpc/envs/development/access_context.auto.tfvars
    mv 3-networks-svpc/envs/nonproduction/access_context.auto.tfvars.disabled  3-networks-svpc/envs/nonproduction/access_context.auto.tfvars
    mv 3-networks-svpc/envs/production/access_context.auto.tfvars.disabled  3-networks-svpc/envs/production/access_context.auto.tfvars

    # restore common.auto.tfvars in main module
    mv 3-networks-svpc/envs/development/common.auto.tfvars.disabled  3-networks-svpc/envs/development/common.auto.tfvars
    mv 3-networks-svpc/envs/nonproduction/common.auto.tfvars.disabled  3-networks-svpc/envs/nonproduction/common.auto.tfvars
    mv 3-networks-svpc/envs/production/common.auto.tfvars.disabled  3-networks-svpc/envs/production/common.auto.tfvars
}

function shared(){
    # restore backend configs in main module
    mv 3-networks-svpc/envs/shared/backend.tf.disabled  3-networks-svpc/envs/shared/backend.tf

    # restore access_context.auto.tfvars in main module
    mv 3-networks-svpc/envs/shared/access_context.auto.tfvars.disabled  3-networks-svpc/envs/shared/access_context.auto.tfvars

    # restore common.auto.tfvars in main module
    mv 3-networks-svpc/envs/shared/common.auto.tfvars.disabled  3-networks-svpc/envs/shared/common.auto.tfvars

    # restore shared.auto.tfvars in main module
    mv 3-networks-svpc/envs/shared/shared.auto.tfvars.disabled  3-networks-svpc/envs/shared/shared.auto.tfvars
}

function projects(){
    # restore backend configs in main module
    mv 4-projects/ml_business_unit/development/backend.tf.disabled 4-projects/ml_business_unit/development/backend.tf
    mv 4-projects/ml_business_unit/nonproduction/backend.tf.disabled 4-projects/ml_business_unit/nonproduction/backend.tf
    mv 4-projects/ml_business_unit/production/backend.tf.disabled 4-projects/ml_business_unit/production/backend.tf
    mv 4-projects/ml_business_unit/shared/backend.tf.disabled 4-projects/ml_business_unit/shared/backend.tf

    # restore access_context.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/access_context.auto.tfvars.disabled 4-projects/ml_business_unit/development/access_context.auto.tfvars
    mv 4-projects/ml_business_unit/nonproduction/access_context.auto.tfvars.disabled 4-projects/ml_business_unit/nonproduction/access_context.auto.tfvars
    mv 4-projects/ml_business_unit/production/access_context.auto.tfvars.disabled 4-projects/ml_business_unit/production/access_context.auto.tfvars

    # restore ml_business_unit.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/ml_business_unit.auto.tfvars.disabled 4-projects/ml_business_unit/development/ml_business_unit.auto.tfvars
    mv 4-projects/ml_business_unit/nonproduction/ml_business_unit.auto.tfvars.disabled 4-projects/ml_business_unit/nonproduction/ml_business_unit.auto.tfvars
    mv 4-projects/ml_business_unit/production/ml_business_unit.auto.tfvars.disabled 4-projects/ml_business_unit/production/ml_business_unit.auto.tfvars

    # restore ENVS.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/development.auto.tfvars.disabled 4-projects/ml_business_unit/development/development.auto.tfvars
    mv 4-projects/ml_business_unit/nonproduction/nonproduction.auto.tfvars.disabled 4-projects/ml_business_unit/nonproduction/nonproduction.auto.tfvars
    mv 4-projects/ml_business_unit/production/production.auto.tfvars.disabled 4-projects/ml_business_unit/production/production.auto.tfvars
    mv 4-projects/ml_business_unit/shared/shared.auto.tfvars.disabled 4-projects/ml_business_unit/shared/shared.auto.tfvars

    # restore common.auto.tfvars in main module
    mv 4-projects/ml_business_unit/development/common.auto.tfvars.disabled 4-projects/ml_business_unit/development/common.auto.tfvars
    mv 4-projects/ml_business_unit/nonproduction/common.auto.tfvars.disabled 4-projects/ml_business_unit/nonproduction/common.auto.tfvars
    mv 4-projects/ml_business_unit/production/common.auto.tfvars.disabled 4-projects/ml_business_unit/production/common.auto.tfvars
    mv 4-projects/ml_business_unit/shared/common.auto.tfvars.disabled 4-projects/ml_business_unit/shared/common.auto.tfvars

}

function appinfra(){
    # restore backend configs in main module
    mv 5-app-infra/ml_business_unit/development/backend.tf.disabled 5-app-infra/ml_business_unit/development/backend.tf
    mv 5-app-infra/ml_business_unit/nonproduction/backend.tf.disabled 5-app-infra/ml_business_unit/nonproduction/backend.tf
    mv 5-app-infra/ml_business_unit/production/backend.tf.disabled 5-app-infra/ml_business_unit/production/backend.tf

    # restore ENVS.auto.tfvars in main module
    mv 5-app-infra/ml_business_unit/development/bu1-development.auto.tfvars.disabled 5-app-infra/ml_business_unit/development/bu1-development.auto.tfvars
    mv 5-app-infra/ml_business_unit/nonproduction/bu1-nonproduction.auto.tfvars.disabled 5-app-infra/ml_business_unit/nonproduction/bu1-nonproduction.auto.tfvars
    mv 5-app-infra/ml_business_unit/production/bu1-production.auto.tfvars.disabled 5-app-infra/ml_business_unit/production/bu1-production.auto.tfvars

    # restore common.auto.tfvars in main module
    mv 5-app-infra/ml_business_unit/development/terraform.tfvars.disabled 5-app-infra/ml_business_unit/development/terraform.tfvars
    mv 5-app-infra/ml_business_unit/nonproduction/terraform.tfvars.disabled 5-app-infra/ml_business_unit/nonproduction/terraform.tfvars
    mv 5-app-infra/ml_business_unit/production/terraform.tfvars.disabled 5-app-infra/ml_business_unit/production/terraform.tfvars
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
    -o|--org)
      org
      shift
      ;;
    -e|--envs)
      envs
      shift
      ;;
    -a|--appinfra)
      appinfra
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
