#!/bin/bash

#
# A simple test script to perform basic scenario tests
# against the built image. 
#
# See the "Local Testing" section of DEVELOPMENT.md
#

LOGFILE="logs/$(date +"%Y.%m.%d.%H.%M.%S").test.log"
mkdir -p logs

function printMessage(){
  if [ ! -z "$TESTNAME" ]
  then
    echo "* [Test: $TESTNAME] $1" | tee "$LOGFILE"
  else
    echo "* $1 " | tee "$LOGFILE"
  fi
}

function printError(){
  if [ ! -z "$TESTNAME" ]
  then
    echo "!! [Test: $TESTNAME] $1" | tee "$LOGFILE"
  else
    echo "!! $1 " | tee "$LOGFILE"
  fi
}

function interrupted(){
  printMessage "Interrupt detected, cleaning up..."
  cleanUp
  exit 1
}

function cleanUp(){
  if [ ! -z "$BASE_COMPOSE" ]
  then
    printMessage "Removing resources"
    $BASE_COMPOSE down --volumes --remove-orphans --timeout=30 > /dev/null 2>&1
  fi
}

function testHealthCheckStatus(){
  if [ -z "$1" ]
  then
    return 1
  fi
  test $(docker inspect --format="{{.State.Health.Status}}" "$1") = "healthy"
}

function basicComposeScenarioHeathCheckTest(){
  if [ -z "$TESTNAME" ]
  then
    printError "INTERNAL ERROR: TESTNAME not defined"
    return 1
  fi

  if [ -z "$BASE_COMPOSE" ]
  then
    printError "INTERNAL ERROR: BASE_COMPOSE not defined"
    return 1
  fi

  printMessage "Starting containers for test"
  $BASE_COMPOSE up -d > /dev/null 2>&1
  if (( $? != 0 ))
  then
    printError "Unable to start the test"
    return 1
  fi

  ARCHIVA_CONTAINER_ID=$($BASE_COMPOSE ps -q archiva)
  if (( $? != 0 ))
  then
    printError "Unable to locate the archiva container id"
    return 1
  fi

  MAX_WAIT=${MAX_WAIT:-60}
  WAITED=0
  printMessage "Waiting for container to be healthy"
  while ! testHealthCheckStatus $ARCHIVA_CONTAINER_ID
  do
    if (( WAITED == MAX_WAIT ))
    then
      printError "Archiva did not start properly"
      return 1
    fi
    sleep 1
    (( WAITED++ ))
  done

  printMessage "Archiva started properly"
  return 0
}

if [ -z "$TAG" ]
then
  echo "TAG not specified, exiting"
  exit 1
fi

export TAG

trap interrupted SIGINT SIGQUIT SIGHUP SIGABRT SIGKILL

#main()

echo "Logging to $LOGFILE"

if [ -z "$TEST_ONLY" ] || [ "$TEST_ONLY" == "basic" ]
then
  TESTNAME="Basic deployment"
  BASE_COMPOSE="docker-compose -f docker-compose.yaml"
  basicComposeScenarioHeathCheckTest
  BASIC_TEST_PASSED=$?
  cleanUp
else
  BASIC_TEST_PASSED=0
fi

if [ -z "$TEST_ONLY" ] || [ "$TEST_ONLY" == "proxy" ]
then
  TESTNAME="HTTPS Proxy"
  BASE_COMPOSE="docker-compose -f docker-compose.yaml -f docker-compose.nginx-https.yaml"
  basicComposeScenarioHeathCheckTest
  NGINX_TEST_PASSED=$?

  if (( NGINX_TEST_PASSED == 0 ))
  then
    RESPONSE_CODE=$(curl -m 1 -k -s -o /dev/null -w '%{http_code}'\
      https://localhost:${HTTPS_PORT:-8443})
    if (( RESPONSE_CODE == 200 ))
    then
      printMessage "External request to proxy succeeded"
    else
      printError "External request to proxy failed"
      NGINX_TEST_PASSED=1
    fi
  fi 
  cleanUp
else
  NGINX_TEST_PASSED=0
fi

if [ -z "$TEST_ONLY" ] || [ "$TEST_ONLY" == "mysql" ]
then
  TESTNAME="MySQL user db"
  BASE_COMPOSE="docker-compose -f docker-compose.yaml -f docker-compose.mysql.yaml"
  # Wait longer for the mysql test, since we have to allow the mysql container to initalize
  MAX_WAIT=90
  basicComposeScenarioHeathCheckTest
  MYSQL_TEST_PASSED=$?

  if (( MYSQL_TEST_PASSED == 0 ))
  then
    TABLE_OUTPUT="$($BASE_COMPOSE exec mysql mysql -u archiva --password=archiva -e "show tables" archiva)"
    # Check that an expected table exists
    echo "$TABLE_OUTPUT" | grep -q JDOUSER
    if (( $? == 0 ))
    then
      printMessage "Detected JDOUSER table"
    else
      printError "Did not detect JDOUSER table"
      MYSQL_TEST_PASSED=1
    fi
  fi
else
  MYSQL_TEST_PASSED=0
fi

cleanUp

#
# Step 3: Perform the mysql test
#
test $BASIC_TEST_PASSED -eq 0 &&\
  test $NGINX_TEST_PASSED -eq 0 &&\
  test $MYSQL_TEST_PASSED -eq 0

exit $?
