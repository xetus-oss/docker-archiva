#!/bin/bash

set -e

#
# This healthcheck tries the unauthenticated ping
# endpoint available in archiva rest server
#

ORIGIN_BASE_URL=${PROXY_BASE_URL:-http://localhost:8080/}
LOCAL_BASE_URL=http://localhost:8080/
REST_PING_PATH=restServices/archivaServices/pingService/ping
QUERY_PATH="${LOCAL_BASE_URL}${REST_PING_PATH}"

RESPONSE_CODE=$(curl -m 1 -s -o /dev/null -w '%{http_code}' \
  -H "Origin: ${ORIGIN_BASE_URL}" $QUERY_PATH)

exec test $RESPONSE_CODE -eq 200