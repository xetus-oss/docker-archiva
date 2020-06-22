#!/bin/bash

#
# A simple test script to perform basic scenario tests
# against the built image. 
#
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

trap interrupted SIGINT SIGQUIT SIGHUP SIGABRT SIGKILL

#main()

echo "Logging to $LOGFILE"

#
# Perform a basic deployment using the standard 
# options from the docker-compose.yaml
#
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

#
# Perform a deployment with proxy support. Relies
# on the docker-compose.ngnix-https.yaml
#
if [ -z "$TEST_ONLY" ] || [ "$TEST_ONLY" == "proxy" ]
then
  TESTNAME="HTTPS Proxy"
  BASE_COMPOSE="docker-compose -f docker-compose.yaml -f docker-compose.nginx-https.yaml"
  basicComposeScenarioHeathCheckTest
  NGINX_TEST_PASSED=$?

  if (( NGINX_TEST_PASSED == 0 ))
  then
    RESPONSE_CODE=$($BASE_COMPOSE exec archiva \
      curl -m 1 -k -s -o /dev/null -w '%{http_code}' \
      https://nginx:${HTTPS_PORT:-8443})
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

#
# Perform a deployment with mysql support. Relies
# on the docker-compose.mysql.yaml
#
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
  cleanUp
else
  MYSQL_TEST_PASSED=0
fi

if [ -z "$TEST_ONLY" ] || [ "$TEST_ONLY" == "cacerts" ]
then
  TESTNAME="Custom CA Certs"
  BASE_COMPOSE="docker-compose -f docker-compose.yaml -f docker-compose.cacerts.yaml"
  basicComposeScenarioHeathCheckTest
  CUSTOM_CA_CERTS_TEST_PASSED=$?
  if (( $CUSTOM_CA_CERTS_TEST_PASSED == 0 ))
  then
    # Go check that the cacerts got loaded into the container's cacerts file
    CERT_LIST="$(docker-compose exec archiva keytool \
      -list -v -storepass 'changeit'\
      --noprompt \
      -keystore /etc/ssl/certs/java/cacerts)"
    if (( $? != 0 ))
    then
      printError "Could not list installed cacerts, cannot complete test"
      CUSTOM_CA_CERTS_TEST_PASSED=1
    else
      EXPECTED_CERTS=("archiva_test_ca_1.crt" "archiva_test_ca_2.crt")
      for expected_cert_alias in "${EXPECTED_CERTS[@]}"
      do
        echo "$CERT_LIST" | grep -q "Alias name: $expected_cert_alias"
        if (( $? != 0 ))
        then
          printError "Expected certificate not installed: $expected_cert_alias"
          CUSTOM_CA_CERTS_TEST_PASSED=1
          break 
        fi
      done
    fi
  fi
  cleanUp
else
  CUSTOM_CA_CERTS_TEST_PASSED=0
fi

test $BASIC_TEST_PASSED -eq 0 &&\
  test $NGINX_TEST_PASSED -eq 0 &&\
  test $MYSQL_TEST_PASSED -eq 0 &&\
  test $CUSTOM_CA_CERTS_TEST_PASSED

exit $?