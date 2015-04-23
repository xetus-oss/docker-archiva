#!/bin/bash

source /data_dirs.env

mkdir -p /archiva-data
cd /opt/archiva

# Add mysql-connect lib
sed -i '44i\
wrapper.java.classpath.27=%REPO_DIR%/mysql-connector-java-5.1.35.jar\
' conf/wrapper.conf

for datadir in "${DATA_DIRS[@]}"; do
  if [ -e $datadir ]
  then
    mv ${datadir} ${datadir}-template
  fi
  ln -s /archiva-data/${datadir#/*} ${datadir}
done

chown -R archiva:archiva /archiva-data/
chown archiva:archiva /etc/ssl/certs/java/cacerts
