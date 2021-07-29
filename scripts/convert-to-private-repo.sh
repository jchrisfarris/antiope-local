#!/bin/bash -e

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

#
# Script to create a new Antiope Management Repo
#

REPO_URL=$1

if [ -z "$REPO_URL" ] ; then
	echo "Usage: $0 <GitHub Repo URL - https://github.com/YOURORG/REPONAME.git> "
	exit 1
fi

# first make sure we're in the right directory
if [ ! -d .git ] ; then
	echo "This should be run from the root of the antiope-local repo as ./scripts/convert-to-private-repo.sh"
	exit 1
fi

if [ -e antiope/.git ] || [ -e antiope-aws-module/.git ] || [ -e antiope-hunt-scripts/.git ] ; then
	echo "Found Submodules in this repo. Please run this script _before_ downloading the submodules. Aborting"
	exit 1
fi

# Remove the .git from the original public repo
rm -rf .git

# now initalize this directory as a new repo
git init

# Add everything
git add .
git commit -m "Migration from antiope-local repo"

# Set the upstream
git branch -M main
git remote add origin $REPO_URL

# # Go forth and fetch the submodules
git submodule add https://github.com/jchrisfarris/antiope
git submodule add https://github.com/jchrisfarris/antiope-aws-module
git submodule add https://github.com/jchrisfarris/antiope-hunt-scripts

git add .
git commit -m "Adding latest submodules"

# push!
git push -u origin main