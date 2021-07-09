#!/bin/bash -e

#
# Script to create a new Antiope environment
#

COMPANY=$1
ENVIRONMENT=$2

if [ -z "$ENVIRONMENT" ] ; then
	echo "Usage: $0 <company_identifier> <environment_identified> "
	exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ] ; then
	echo "Default region is not set."
	echo "	export AWS_DEFAULT_REGION=us-east-1"
	exit 1
fi

# create a sample config file
cp config.SAMPLE config.$ENVIRONMENT
sed -i '' s/YOURCOMPANY/$COMPANY/g config.$ENVIRONMENT
sed -i '' s/ENVIRONMENT/$ENVIRONMENT/g config.$ENVIRONMENT

# Use the SAMPLE Manifest
cp Manifest/Antiope-SAMPLE-Manifest.yaml Manifest/Antiope-$ENVIRONMENT-Manifest.yaml
sed -i '' s/YOURCOMPANY/$COMPANY/g Manifest/Antiope-$ENVIRONMENT-Manifest.yaml
sed -i '' s/ENVIRONMENT/$ENVIRONMENT/g Manifest/Antiope-$ENVIRONMENT-Manifest.yaml

# Create Manifest files

cft-generate-manifest -m Manifest/Antiope-Bucket-$ENVIRONMENT-Manifest.yaml -t antiope/cloudformation/antiope-bucket-Template.yaml \
	--stack-name $COMPANY-antiope-bucket-$ENVIRONMENT --region $AWS_DEFAULT_REGION --termination-protection

