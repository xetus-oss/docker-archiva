#!/bin/bash

#
# See the README file for usage!
#
set -e
source /config.env

if [[ -z "$SMTP_HOST" && -z "$JETTY_CONFIG_PATH" ]]
then
  echo "WARNING: SMTP_HOST not set, Archiva cannot send emails!" > /dev/stderr
fi

if [ -e $JVM_MAX_MEM ]
then
  echo "WARNING: JVM_MAX_MEM has been depreciated and is no longer used!"
fi

DB_TYPE=${DB_TYPE:-derby}
JETTY_CONFIG_PATH=${JETTY_CONFIG_PATH:-/tmp/jetty.xml}
# A preventative measure to avoid OOM errors
MALLOC_ARENA_MAX=${MALLOC_ARENA_MAX:-2}

#
# Initialize the volume data directories
#
for datadir in "${EXTERNAL_DATA_DIRS[@]}"
do
  if [ ! -e ${ARCHIVA_BASE}/${datadir} ]
  then
    if [ -e ${TEMPLATE_ROOT}/${datadir} ]
    then
      echo "Populating $datadir from template..."
      cp -pr ${TEMPLATE_ROOT}/${datadir} ${ARCHIVA_BASE}/${datadir}
    else
      echo "Creating empty directory for $datadir..."
      mkdir ${ARCHIVA_BASE}/${datadir}
    fi
  fi
done

#
# Setup the managed jetty.xml if it does not already exist
#
if [ ! -e "$JETTY_CONFIG_PATH" ]
then
  JETTY_TEMPLATE_ROOT="${TEMPLATE_ROOT}/jetty-conf/"
  if [ "$DB_TYPE" == "mysql" ]
  then
     DB_FRAGMENT_FILE=${JETTY_TEMPLATE_ROOT}/mysql-db-fragment.xml
     MYSQL_JDBC_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
     echo "Using MySQL database at: $MYSQL_JDBC_URL"
  elif [ "$DB_TYPE" == "derby" ]
  then
     DB_FRAGMENT_FILE=${JETTY_TEMPLATE_ROOT}/derby-db-fragment.xml
  else
    echo "Unknown database type $DB_TYPE - must be either mysql or derby"
    exit 1
  fi
   cat ${JETTY_TEMPLATE_ROOT}/jetty-template.xml |\
     sed -e "/DB_CONFIGURATION_FRAGMENT/r $DB_FRAGMENT_FILE" \
       -e "/DB_CONFIGURATION_FRAGMENT/d" > "$JETTY_CONFIG_PATH"
fi

#
# Add any ca certificates specified by the user to the
# container's cacerts keystore.
#
if [ -e /certs ]
then
  for certfile in `find /certs -type f \( -iname \*.crt -o -iname \*.pem \)`
  do

    CERT_ALIAS="${certfile##*/}"
    echo "Adding certificate $CERT_ALIAS"

    # First, delete the entry, if it exsits
    set +e
    keytool -delete -alias "$CERT_ALIAS"\
       -keystore /etc/ssl/certs/java/cacerts\
       -storepass changeit\
       -noprompt > /dev/null 2>&1
    set -e

    keytool -import -trustcacerts -alias "$CERT_ALIAS"\
      -keystore /etc/ssl/certs/java/cacerts\
      -file "$certfile"\
      -storepass changeit\
      -noprompt
  done
fi

#
# Setup the JVM enviroment arguments
#
export CLASSPATH=$(find /archiva/lib -name "*.jar"\
  | sed '/wrapper.jar/d' | awk '{ printf("%s:", $1) }')

JVM_OPTS=(
  "-Dappserver.home=."
  "-Dappserver.base=$ARCHIVA_BASE"
  "-Djetty.logs=${ARCHIVA_BASE}/logs"
  "-Djava.io.tmpdir=${ARCHIVA_BASE}/temp"
  "-DAsyncLoggerConfig.WaitStrategy=Block"
  "-Darchiva.repositorySessionFactory.id=jcr"
  "-XX:+UseContainerSupport"
)

#
# Set aliases to the runtime & initialization jvm
# properties used by Archiva v2
#
REDBACK_PREFIX="org.apache.archiva.redback"
REDBACK_RT_PREFIX="${REDBACK_PREFIX}RuntimeConfiguration.configurationProperties"
WEBAPP_PREFIX="org.apache.archiva.webapp"

#
# If a proxy is used set all the necessary properties
#
if [ ! -z "$PROXY_BASE_URL" ]
then
  JVM_OPTS+=(
    "-D${REDBACK_PREFIX}.rest.baseUrl=${PROXY_BASE_URL}"
    "-D${REDBACK_RT_PREFIX}.baseUrl.url=${PROXY_BASE_URL}"
    "-D${REDBACK_PREFIX}.rest.baseUrl=${PROXY_BASE_URL}"
    "-D${REDBACK_RT_PREFIX}.rest.baseUrl=${PROXY_BASE_URL}"
    "-D${WEBAPP_PREFIX}.ui.applicationUrl=${PROXY_BASE_URL}"
  )
fi

#
# Perform any upgrades required for the v2 image.
#
./upgrade_v2.sh

cd ${ARCHIVA_HOME}
export MYSQL_JDBC_URL
exec java $JVM_EXTRA_OPTS ${JVM_OPTS[@]}\
  org.eclipse.jetty.start.Main\
  "$JETTY_CONFIG_PATH"