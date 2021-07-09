# Copyright 2020-2021 Chris Farris <chrisf@primeharbor.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifndef env
$(error env is not set)
endif

include config.$(env)
export


ifndef MAIN_STACK_NAME
$(error MAIN_STACK_NAME is not set)
endif

ifndef BUCKET
$(error BUCKET is not set)
endif

ifndef version
	export version := $(shell date +%Y%b%d-%H%M)
endif


# Global Vars
export DEPLOY_PREFIX=deploy-packages

# Local to this Makefile Vars
CONFIG_PREFIX=config-files
MAIN_TEMPLATE=antiope/cloudformation/antiope-Template.yaml
OUTPUT_TEMPLATE_PREFIX=antiope-Template-Transformed
OUTPUT_TEMPLATE=$(OUTPUT_TEMPLATE_PREFIX)-$(version).yaml
TEMPLATE_URL ?= https://s3.amazonaws.com/$(BUCKET)/$(DEPLOY_PREFIX)/$(OUTPUT_TEMPLATE)

# Create and Package the Lambda Layer, copy it to S3
layer:
	cd antiope && $(MAKE) layer

# Execute Code tests to validate syntax
test:
	cd antiope && $(MAKE) test

# Add the library dependencies into the lamda folders before cloudformation package is run
deps:
	cd antiope && $(MAKE) deps


#
# Deploy New Code Targets
#

# Everything and the post-deploy scripts
install: deploy post-deploy

# Everything to deploy a fresh version of code
deploy: test cft-validate package cft-deploy

# Package up the nested stacks and code which are copied to S3. Then copy the transformed template to S3 where it will be deployed from
package: deps
	@aws cloudformation package --template-file $(MAIN_TEMPLATE) --s3-bucket $(BUCKET) --s3-prefix $(DEPLOY_PREFIX)/transform --output-template-file cloudformation/$(OUTPUT_TEMPLATE)  --metadata build_ver=$(version)
	@aws s3 cp cloudformation/$(OUTPUT_TEMPLATE) s3://$(BUCKET)/$(DEPLOY_PREFIX)/
# 	rm cloudformation/$(OUTPUT_TEMPLATE)

# Actually perform the deploy using cft-deploy and the manifest file (for params) from the code bundle and templates in the S3 bucket
cft-deploy: package
ifndef MANIFEST
	$(error MANIFEST is not set)
endif
ifndef LAYER_URL
	$(error LAYER_URL is not set)
endif
	cft-deploy -m Manifest/$(MANIFEST) --template-url $(TEMPLATE_URL) pTemplateURL=$(TEMPLATE_URL) pBucketName=$(BUCKET) pAWSLambdaLayerPackage=$(LAYER_URL) --force

# Execute the post-deploy scripts required to make it all work
post-deploy:
# 	cd aws-inventory && $(MAKE) post-deploy
	cd antiope/cognito && $(MAKE) post-deploy
	cd antiope/search-cluster && $(MAKE) post-deploy

#
# Promote Existing Code Targets
#

# promote an existing stack to a new environment
# Assumes cross-account access to the lower environment's DEPLOY_PREFIX
promote: cft-promote push-config

# Run cft-deploy with a different manifest on a previously uploaded code bundle and transformed template
cft-promote:
ifndef MANIFEST
	$(error MANIFEST is not set)
endif
ifndef LAYER_URL
	$(error LAYER_URL is not set)
endif
ifndef template
	$(error template is not set)
endif
	cft-deploy -m Manifest/$(MANIFEST) --template-url $(template) pTemplateURL=$(template) pBucketName=$(BUCKET) pAWSLambdaLayerPackage=$(LAYER_URL) --force


#
# Testing & Cleanup Targets
#
# Validate all the CFTs. Inventory is so large it can only be validated from S3
cft-validate:
	cd antiope && $(MAKE) cft-validate

# Clean up dev artifacts
clean:
	cd antiope && $(MAKE) clean

# Run pep8 style checks on lambda
pep8:
	cd antiope && $(MAKE) pep8

# Purge all deploy packages in the Antiope bucket.
# WARNING - if you do this, you will no longer be able to promote code.
purge-deploy-packages:
	aws s3 rm s3://$(BUCKET)/$(DEPLOY_PREFIX)/ --recursive

# Pull down the deploy packages from the Antiope Bucket.
# Use this when you want to see what Cloudformation serverless transforms has done
sync-deploy-packages:
	aws s3 sync s3://$(BUCKET)/$(DEPLOY_PREFIX)/ Scratch/$(DEPLOY_PREFIX)/ --delete

#
# Management Targets
#


# Copy down all the reports Antiope has created
sync-reports:
	aws s3 sync s3://$(BUCKET)/Reports Reports/$(MAIN_STACK_NAME)
	open Reports/$(MAIN_STACK_NAME)

# Manually trigger the Antiope Stepfunction
trigger-inventory:
	@./antiope/bin/trigger_inventory.sh $(MAIN_STACK_NAME)

# Disable the CloudWatch Event that triggers Antiope
disable-inventory:
	$(eval EVENT := $(shell aws cloudformation describe-stacks --stack-name $(MAIN_STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`TriggerEventName`].OutputValue' --output text --region $(AWS_DEFAULT_REGION)))
	aws events disable-rule --name $(EVENT) --output text --region $(AWS_DEFAULT_REGION)

# Enable the CloudWatch Event that triggers Antiope
enable-inventory:
	$(eval EVENT := $(shell aws cloudformation describe-stacks --stack-name $(MAIN_STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`TriggerEventName`].OutputValue' --output text --region $(AWS_DEFAULT_REGION)))
	aws events enable-rule --name $(EVENT) --output text --region $(AWS_DEFAULT_REGION)


python-requirements:
	pip3 install -r requirements.txt

python-env:
	python3 -m venv .env-$(env)
	@echo "now run:\n\tsource .env-$(env)/bin/activate"

python-env-activate:
	@echo "You need to run this from the parent shell: \n\tsource .env-$(env)/bin/activate"
