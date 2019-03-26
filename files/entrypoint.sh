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

JVM_MAX_MEM=${JVM_MAX_MEM:-512}
DB_TYPE=${DB_TYPE:-derby}
JETTY_CONFIG_PATH=${JETTY_CONFIG_PATH:-/tmp/jetty.xml}

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
  "-Xmx${JVM_MAX_MEM}m"
  "-Xms${JVM_MAX_MEM}m"
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
# Fix the repository locations in the archiva.xml 
# configuration from the v2-legacy image
#
# note: this is a no-op if the archiva config doesn't
# need to be changed.
#
REPO_LOCATIONS_TO_FIX=$(grep "<location>./repositories/" "${ARCHIVA_BASE}/conf/archiva.xml" &2>&1)
if [ ! -z "$REPO_LOCATIONS_TO_FIX" ]
then
  echo 
  echo "================"
  echo "Fixing relative repository location in configuration file."
  echo 
  echo "!! ADDITIONAL ACTION IS LIKELY REQUIRED !!"
  echo 
  echo "Your Archiva UI might display artifacts that aren't actually "
  echo "persisted! To remove the ghost artifacts from the UI:"
  echo
  echo "  1. Make a backup of your archiva configuration file (update paths below as appropriate):"
  echo
  echo "      cp /archiva-data/conf/archiva.xml /archiva-data/conf/archiva.xml.bk"
  echo 
  echo "  2. In the Archiva UI, delete all repositories via the Repositories page."
  echo "     Do *NOT* delete the contents!"
  echo
  echo "  3. Revert the Archiva configuration using your backup: "
  echo
  echo "      cp /archiva-data/conf/archiva.xml.bk to /archiva-data/conf/archiva.xml"
  echo
  echo "  4. Restart the archiva container"
  echo
  echo "  5. In the Archiva UI, re-assign user permissions for the repositories via"
  echo "     the Users => Manage pages."
  echo
  echo "For more details see: https://github.com/xetus-oss/docker-archiva/issues/13"
  echo "================"
  echo

  cat ${ARCHIVA_BASE}/conf/archiva.xml | \
    sed -E 's@<(location|indexDir)>\./repositories/(.*)</(location|indexDir)>@<\1>/archiva-data/repositories/\2</\3>@' > \
      ${ARCHIVA_BASE}/conf/archiva.xml

  cp ${ARCHIVA_BASE}/conf/archiva.xml ${ARCHIVA_BASE}/conf/archiva.xml.bk

  # TODO: make this more specific; i.e. - /repositories/repositories/[internal|snapshot]?
  if [ -e "${ARCHIVA_BASE}/repositories/repositories" ]
  then
    echo "Removing old .indexer files stored under ${ARCHIVA_BASE}/repositories/repositories..."
    rm -r ${ARCHIVA_BASE}/repositories/repositories
  fi
fi

cd ${ARCHIVA_HOME}
export MYSQL_JDBC_URL
exec java $JVM_EXTRA_OPTS ${JVM_OPTS[@]}\
  org.eclipse.jetty.start.Main\
  "$JETTY_CONFIG_PATH"