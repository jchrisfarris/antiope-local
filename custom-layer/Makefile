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

include ../config.$(env)
export

ifndef pythonver
# $(error env is not set)
	pythonver ?= python3.7
endif

ifndef version
	export version := $(shell date +%Y%b%d-%H%M)
endif

export DEPLOY_PREFIX=deploy-packages
export LAYER_PACKAGE=antiope-custom-lambda-layer-$(version).zip

# Static, not sure if needed??
PYTHON=python3
PIP=pip3

# All the dependencies required to call the API to create the layer
custom-layer: clean deps zipfile upload

clean:
	rm -rf python *.zip discosuite/__pycache__ *.egg-info

# Create the package Zip. Assumes all tests were done
zipfile:
	zip -r $(LAYER_PACKAGE) python

# Install the required Libraries
deps:
	$(PIP) install -r requirements.txt -t python/lib/$(pythonver)/site-packages/ --upgrade

# Upload the completed ZIP file to S3 so it can be used by Lambda service for the layer
upload:
ifndef BUCKET
	$(error BUCKET is not set)
endif
ifndef DEPLOY_PREFIX
	$(error DEPLOY_PREFIX is not set)
endif
	aws s3 cp $(LAYER_PACKAGE) s3://$(BUCKET)/$(DEPLOY_PREFIX)/$(LAYER_PACKAGE)
	@echo "Your Lambda Layer is s3://$(BUCKET)/$(DEPLOY_PREFIX)/$(LAYER_PACKAGE)"

