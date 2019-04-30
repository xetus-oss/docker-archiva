#!/bin/bash

set -eo pipefail

#
# Build the most recent snapshot, if specified in the environment
#
BUILD_SNAPSHOT_RELEASE=${BUILD_SNAPSHOT_RELEASE:-false}
if [ $BUILD_SNAPSHOT_RELEASE = true ]
then
  ARCHIVA_SNAPSHOTS_BASE="https://archiva-repository.apache.org/archiva/repository/snapshots/org/apache/archiva/archiva-jetty/2.2.5-SNAPSHOT/"

  BUILD_NO=$(curl -s "${ARCHIVA_SNAPSHOTS_BASE}maven-metadata.xml" |\
    grep buildNumber | cut -f2 -d'>' | cut -f1 -d'<')

  FILE_NAME=$(curl -s "$ARCHIVA_SNAPSHOTS_BASE" |\
    grep archiva-jetty | grep "${BUILD_NO}-bin.tar.gz<"|\
    awk 'BEGIN{FS="href=\""} { print $2 }' |\
    cut -f1 -d\")

  MD5SUM=$(curl "${ARCHIVA_SNAPSHOTS_BASE}${FILE_NAME}.md5")

  ARCHIVA_RELEASE_URL=${ARCHIVA_SNAPSHOTS_BASE}${FILE_NAME}
  ARCHIVA_RELEASE_MD5SUM=${MD5SUM}
fi

#
# Archiva binary parameters
#
ARCHIVA_RELEASE_URL=${ARCHIVA_RELEASE_URL:-https://www-us.apache.org/dist/archiva/2.2.4/binaries/apache-archiva-2.2.4-bin.tar.gz}
ARCHIVA_RELEASE_MD5SUM=${ARCHIVA_RELEASE_MD5SUM:-597aeb9f42e634ae58256fb99997040f}

#
# MySQL connector parameters
#
MYSQL_CONNECTOR_URL=https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.12/mysql-connector-java-8.0.12.jar
MYSQL_CONNECTOR_MD5SUM=88766727e5e434ceb94315b0dae0e4b4

#
# Download and verify the archiva tarball. Then extract
# it to the default destination
#
echo "Building archiva from $ARCHIVA_RELEASE_URL"
cd /tmp/
curl -O $ARCHIVA_RELEASE_URL
ARCHIVA_RELEASE_FILENAME=$(ls -C1 | grep archiva | grep .tar.gz)
echo "ARCHIVA_RELEASE_FILENAME=${ARCHIVA_RELEASE_FILENAME}"
ACTUAL_ARCHIVA_RELEASE_MD5SUM="$(md5sum /tmp/${ARCHIVA_RELEASE_FILENAME} | cut -f1 -d' ')"
if [ "$ACTUAL_ARCHIVA_RELEASE_MD5SUM" != "$ARCHIVA_RELEASE_MD5SUM" ]
then
  echo "archiva release md5sum did not match expected value"
  exit 1
fi

mkdir -p $ARCHIVA_HOME && cd $ARCHIVA_HOME
tar xzf /tmp/${ARCHIVA_RELEASE_FILENAME} --strip-components 1
rm -v /tmp/${ARCHIVA_RELEASE_FILENAME}

#
# Download and verify the mysql connector
#
cd /tmp/
curl -O $MYSQL_CONNECTOR_URL
MYSQL_CONNECTOR_FILENAME=$(ls -C1 | grep mysql-connector- | grep jar)
ACTUAL_MYSQL_CONNECTOR_MD5SUM=$(md5sum /tmp/${MYSQL_CONNECTOR_FILENAME} | cut -f1 -d' ')
if [ "$ACTUAL_MYSQL_CONNECTOR_MD5SUM" != "$MYSQL_CONNECTOR_MD5SUM" ]
then
  echo "mysql-connector md5sum did not match expected value"
  exit 1
fi
mv -v /tmp/${MYSQL_CONNECTOR_FILENAME} ${ARCHIVA_HOME}/lib/

chown -R archiva:archiva $ARCHIVA_HOME

exit 0;