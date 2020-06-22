#!/bin/bash

#
# A tiny shell script to push do dockerhub from a travis-ci build.
#

REPO=xetusoss/archiva;

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin;

if [ -n "$TRAVIS_TAG" ]
then
  export TAG=${REPO}:${TRAVIS_TAG}
  make push
elif [ "$TRAVIS_PULL_REQUEST" != "false" ]
then
  export TAG="${REPO}:pr-${TRAVIS_PULL_REQUEST}"
  make push
else
 if [ "${TRAVIS_BRANCH}" == "master" ]
 then
  export TAG="${REPO}:develop"
 else
  export TAG="${REPO}:${TRAVIS_BRANCH}"
 fi
 make push
fi