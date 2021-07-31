# antiope-local - Sample Antiope Local Repo

## What this repo is
This repository is intended to host the configuration files and customization to [Antiope](https://github.com/jchrisfarris/antiope).

**Please do not fork this repository!!!** Instead clone this repository and run the [convert-to-private-repo.sh](https://github.com/jchrisfarris/antiope-local/blob/main/scripts/convert-to-private-repo.sh) script.

Antiope uses [cft-deploy](https://github.com/jchrisfarris/cft-deploy) and Manifest files to version control and manage the Cloudformation stack parameters. Additionally environment specific config files are leveraged by the Makefiles. None of these files should **ever** be public.

The Antiope code exists as submodules that should be cloned under this repo. Eventually, the combination of your private version of this repo and the cloned submodules will facilitate a pipeline deployment of Antiope.

Note: In order to avoid a dependency loop, you must first deploy the main antiope stack(s). The [sample custom template](https://github.com/jchrisfarris/antiope-local/blob/main/cloudformation/SAMPLE-Custom-Antiope-Template.yaml) requires the SNS Topics and DynamoDB tables to exist prior to creation.


**After cloning this repo, and converting it private delete this readme content above this line, and customize the following for your company. Consider a Search and Replace on YOURCOMPANY**

-----

# YOURCOMPANY-antiope-local - internal customization & configuration for Antiope

## How to use this repo
This repo contains proprietary code and config for YOURCOMPANY. It should not be made public!!

It is based off of the [Antiope Local Repo](https://github.com/jchrisfarris/antiope-local) which is designed to facilitate the deployment and customization of Antiope.

To use this repo, clone it, then run:
```bash
# Download the Antiope Source from github
scripts/pull_submodules.sh
# create and activate a python environment
python3 -m venv .env
source .env/bin/activate

# Make sure you're on the right antiope branch
cd antiope ; git checkout antiope-2.0

```

You will also need to install [cft-deploy](https://github.com/jchrisfarris/cft-deploy) via [PyPi](https://pypi.org/project/cftdeploy/).

## Environments
Antiope supports multiple environments via config files. To create a new environment, run `./scripts/create_environment.sh YOURCOMPANY ENVNAME` where ENVNAME is the name of the environment to create (ie "dev", "qa", "prod", "george", whatever).

This will create a config.$ENVNAME file, and Manifest files for both Antiope and the Antiope Bucket. The Makefiles all require the use of `env=ENVNAME` to be passed on the make command line.

After running create_environment.sh, you must edit the Manifest files to customize Antiope to your environment.

## Customization
Antiope is intended to be a base upon which you can build your own inventory functions based on your organization's needs. This private repo contains the scripts, cloudformation templates and lambda functions for your customization. [More information on Antiope customization is here](https://github.com/jchrisfarris/antiope/blob/development/docs/Customizations.md)



## Deployment
To deploy a development environment (named "dev"), run the following:

```bash
# You should only need to deploy the bucket once.
cft-deploy -m Manifests/Antiope-Bucket-dev-Manifest.yaml

# You should only update the layer when needed
make layer env=dev

# Deploy the main branch of code
make deploy env=dev

# Deploy the customization stack
make custom-deploy env=dev
```

If you wish to _promote_ code from a lower environment to a higher environment, you can find the current template in the outputs of the existing Cloudformation Stack. Then run:

```bash
make promote env=ENVNAME template=https://YOURBUCKET/TRANSFORMED.yaml
```

This will re-use the existing lambda packages and cloudformation templates.


## Make Targets provided by this repo

* *layer* - Create the necessary Lambda Layer, upload the zipfile and update the config.ENV
* *test* - Execute simple python syntax checking on all the files
* *package* - Runs the `aws cloudformation package` command to zip up the lambda code and transform the CFT per the Serverless Transform. It also copies the transformed template to S3 for use by Cloudformation, and to preserve it for promotion to higher environments.
* *deploy* - Deploys the main antiope from the code base. cft-deploy handles logic to determine if this call is a create-stack or update stack
* *promote* - Deploys the main antiope from an existing Transformed CloudFormation Template hosted in S3. This is used to promote from lower to higher environments
* *clean* - removes temporary files, zips, transformed templates, etc
* *pep8* - runs pep8 against python files for styling guideline checking
* *sync-reports* - Downloads the reports in S3 to the local Reports/ directory
* *trigger-inventory* - Manually fires off the main stepfunction
* *disable-inventory* and *enable-inventory* - Disables or enables the Scheduled CloudWatch event that fires the main stepfunction