#!/bin/bash

#
# A tiny shell script to trigger a dockerhub build during a travis-ci run.
#
set -xe

TRIGGER_URL="https://hub.docker.com/api/build/v1/source/7bd793a9-4dcd-42f8-bd7f-0e9053666cf8/trigger/0e5df6c1-aa54-497a-b0e2-1b68621be630/call/"

if [ -n "$TRAVIS_TAG" ]
then
	jq -n --arg TRAVIS_TAG "$TRAVIS_TAG" \
		'{"source_type": "Tag", "source_name": $TRAVIS_TAG }' > data.json
else
	jq -n --arg TRAVIS_BRANCH "$TRAVIS_BRANCH" \
	  '{"source_type": "Branch", "source_name": $TRAVIS_BRANCH }' > data.json
fi

curl -X POST  -H "Content-Type: application/json"\
 -d @data.json $TRIGGER_URL
