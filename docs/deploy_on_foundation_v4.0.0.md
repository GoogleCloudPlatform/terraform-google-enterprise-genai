# Deploying on top of existing Foundation

# 1-org

- add ml policies
- create org key 

# 2-environment

- create env key (for env-logging, which does not seem to be used)
- create logging project and logging bucket (does not seem to be used, maybe we can remove this)

# 3-network

- configure dns

# 4-projects

- choose business unit to deploy
- deploy ml infra projects (common folder)
- create infra pipeline
- deploy ml envs on business unit

# 5-appinfra

- create service catalog and artifacts build triggers
- trigger service catalog and artifacts custom builds
- adjust vpc-sc to your environment

# 6-mlpipeline

- trigger ml infra pipeline, which will create some resources on development environment for the machine learning project
- on dev env run the notebook and adjust it to your environment
- promote the test application to prod and test the deployed model
