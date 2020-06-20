#!/bin/bash

set -eo pipefail
source /tmp/config.env

#
# Move resources out of the temp directory and change their ownership
#
mv /tmp/config.env /config.env
mv /tmp/entrypoint.sh /entrypoint.sh
mv /tmp/healthcheck.sh /healthcheck.sh
mv /tmp/upgrade_v2.sh /upgrade_v2.sh
chmod +x /entrypoint.sh /healthcheck.sh /upgrade_v2.sh

#
# Initialize the data directories
#
mkdir -p $ARCHIVA_BASE
mkdir -p $TEMPLATE_ROOT

#
# Initialize the template directories
#
for datadir in "${EXTERNAL_DATA_DIRS[@]}"
do
  if [ -e ${ARCHIVA_HOME}/${datadir} ]
  then
    mv -v ${ARCHIVA_HOME}/${datadir} ${TEMPLATE_ROOT}/${datadir}
  fi
done

#
# The template config directory template should only include the 
# archiva.xml and shared.xml files.
#
mv ${TEMPLATE_ROOT}/conf ${TEMPLATE_ROOT}/conf-orig
mkdir ${TEMPLATE_ROOT}/conf
cp ${TEMPLATE_ROOT}/conf-orig/archiva.xml ${TEMPLATE_ROOT}/conf
cp ${TEMPLATE_ROOT}/conf-orig/shared.xml ${TEMPLATE_ROOT}/conf

#
# Setup the jetty-config template directories
#
mkdir ${TEMPLATE_ROOT}/jetty-conf
mv -v /tmp/jetty-template.xml ${TEMPLATE_ROOT}/jetty-conf/
mv -v /tmp/derby-db-fragment.xml ${TEMPLATE_ROOT}/jetty-conf/
mv -v /tmp/mysql-db-fragment.xml ${TEMPLATE_ROOT}/jetty-conf/

# Ensure correct ownership of all of the files that we'll manage.
chown -R archiva:archiva $ARCHIVA_BASE $TEMPLATE_ROOT

#
# Make the cacerts owned by archiva so we can add
# certs to it, if necessary
#
chown archiva:archiva /etc/ssl/certs/java/cacerts
chmod u+w /etc/ssl/certs/java/cacerts
