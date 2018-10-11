#!/bin/bash

set -eo pipefail

#
# Archiva binary parameters
#
ARCHIVA_BIN_URL=https://archive.apache.org/dist/archiva/2.2.3/binaries/apache-archiva-2.2.3-bin.tar.gz
ARCHIVA_BIN_FILENAME=apache-archiva-2.2.3-bin.tar.gz
ARCHIVA_BIN_MD5SUM=085ea9afd0bef07fba71b892af44dc11

#
# MySQL connector parameters
#
MYSQL_CONNECTOR_URL=https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.12/mysql-connector-java-8.0.12.jar
MYSQL_CONNECTOR_FILENAME=mysql-connector-java-8.0.12.jar
MYSQL_CONNECTOR_MD5SUM=88766727e5e434ceb94315b0dae0e4b4

#
# Download and verify the archiva tarball. Then extract
# it to the default destination
#
curl -o /tmp/${ARCHIVA_BIN_FILENAME} $ARCHIVA_BIN_URL
ACTUAL_ARCHIVA_BIN_MD5SUM="$(md5sum /tmp/${ARCHIVA_BIN_FILENAME} | cut -f1 -d' ')"
if [ "$ACTUAL_ARCHIVA_BIN_MD5SUM" != "$ARCHIVA_BIN_MD5SUM" ]
then
  echo "archiva binary md5sum did not match expected value"
  exit 1
fi

mkdir -p $ARCHIVA_HOME && cd $ARCHIVA_HOME
tar xzf /tmp/${ARCHIVA_BIN_FILENAME} --strip-components 1
rm -v /tmp/${ARCHIVA_BIN_FILENAME}

#
# Download and verify the mysql connector
#
curl -o /tmp/${MYSQL_CONNECTOR_FILENAME} $MYSQL_CONNECTOR_URL
ACTUAL_MYSQL_CONNECTOR_MD5SUM=$(md5sum /tmp/${MYSQL_CONNECTOR_FILENAME} | cut -f1 -d' ')
if [ "$ACTUAL_MYSQL_CONNECTOR_MD5SUM" != "$MYSQL_CONNECTOR_MD5SUM" ]
then
  echo "mysql-connector md5sum did not match expected value"
  exit 1
fi
mv -v /tmp/${MYSQL_CONNECTOR_FILENAME} ${ARCHIVA_HOME}/lib/

chown -R archiva:archiva $ARCHIVA_HOME

exit 0;