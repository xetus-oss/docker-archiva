#!/bin/bash

#
# Archiva container bootstrap. See the readme for usage.
#
source /data_dirs.env
JETTY_NEED_CONFIG=false
DATA_PATH=/archiva-data
JETTY_CONF_PATH=/jetty_conf


mkdir -p ${DATA_PATH}/temp
chown archiva:archiva ${DATA_PATH}/temp

if [ ! -e "${DATA_PATH}/conf/jetty.xml" ]
then
  JETTY_NEED_CONFIG=true
fi

cd /opt/archiva
for datadir in "${DATA_DIRS[@]}"; do
  if [ ! -e "${DATA_PATH}/${datadir}" ]
  then
    echo "Installing ${datadir}"
    if [ -e "${datadir}-template" ]
    then
      cp -pr ${datadir}-template ${DATA_PATH}/${datadir}
    else 
      mkdir -p ${DATA_PATH}/${datadir}
    fi
    chown archiva:archiva ${DATA_PATH}/${datadir}
  fi
done

DERBY_DS_JETTY_CONF='<New id="users" class="org.eclipse.jetty.plus.jndi.Resource">
    <Arg>jdbc/users</Arg>
    <Arg>
      <New class="org.apache.tomcat.jdbc.pool.DataSource">
        <Set name="driverClassName">org.apache.derby.jdbc.EmbeddedDriver</Set>
        <Set name="url">jdbc:derby:<SystemProperty name="appserver.base" default=".."/>/data/databases/users;create=true</Set>
        <Set name="username">sa</Set>
        <Set name="maxActive">20</Set>
        <Set name="removeAbandoned">true</Set>
        <Set name="logAbandoned">true</Set>
        <Set name="initialSize">5</Set>
        <Set name="testOnBorrow">true</Set>
        <!-- very rigourous sql query validation -->
        <Set name="validationQuery">select 1</Set>
      </New>
    </Arg>
  </New>

  <New id="usersShutdown" class="org.eclipse.jetty.plus.jndi.Resource">
    <Arg>jdbc/usersShutdown</Arg>
    <Arg>
      <New class="org.apache.tomcat.jdbc.pool.DataSource">
        <Set name="driverClassName">org.apache.derby.jdbc.EmbeddedDriver</Set>
        <Set name="url">jdbc:derby:<SystemProperty name="appserver.base" default=".."/>/data/databases/users</Set>
        <Set name="username">sa</Set>
      </New>
    </Arg>
  </New>'

#
# Config jetty.xml:
# - DB settings
# - HTTPS settings
#
if [ $JETTY_NEED_CONFIG == true ]
then
  cp -f ${JETTY_CONF_PATH}/jetty.xml /tmp/jetty.xml
  #
  # DB configuration 
  #
  # Varaibles:
  # - DB_TYPE
  # - DB_HOST
  # - USERS_DB_NAME
  # - DB_USER
  # - DB_PASS
  

  # is a mysql database linked?
  # requires that the mysql containers have exposed
  # port 3306 respectively.
  if [ -n "${DATABASE_PORT_3306_TCP_ADDR}" ]
  then
    echo "Use linked DB container"
    DB_TYPE=mysql
    DB_HOST=${DB_HOST:-${DATABASE_PORT_3306_TCP_ADDR}:${DATABASE_PORT_3306_TCP_PORT}}
    DB_USER=${DB_USER:-root}
    DB_PASS=${DB_PASS:-${DATABASE_ENV_MYSQL_ROOT_PASSWORD}}
  fi
    
  DB_TYPE=${DB_TYPE:-derby}
  if [ "$DB_TYPE" == "mysql"  ]
  then
    cat ${JETTY_CONF_PATH}/JETTY_DB_CONF | \
      sed 's/{{DB_HOST}}/'"${DB_HOST}"'/' |\
      sed 's,{{USERS_DB_NAME}},'"${USERS_DB_NAME:-archiva_users}"',' |\
      sed 's/{{DB_USER}}/'"${DB_USER}"'/' |\
      sed 's/{{DB_PASS}}/'"${DB_PASS}"'/' > /tmp/.JETTY_DB_CONF
  fi
  if [ "$DB_TYPE" == "derby"  ]
  then
    echo $DERBY_DS_JETTY_CONF > /tmp/.JETTY_DB_CONF
  fi
  cd /tmp
  sed -i '/{{JETTY_DB_CONF}}/r .JETTY_DB_CONF' jetty.xml
  sed -i '/{{JETTY_DB_CONF}}/d' jetty.xml
  rm /tmp/.JETTY_DB_CONF

  #
  # SSL configuration (optional, see readme)
  #
  # Varaibles:
  # - SSL_ENABLED
  # - KEYSTORE_PATH
  # - STORE_AND_CERT_PASS
  if [ "$SSL_ENABLED" = true ]
  then
    KEYSTORE_PATH=${KEYSTORE_PATH:-${DATA_PATH}/ssl/keystore}
    STORE_AND_CERT_PASS=${STORE_AND_CERT_PASS:-changeit}
    if [ ! -e "$KEYSTORE_PATH" ]
      then
      echo "Generating self-signed keystore and certificate for HTTPS support(Dst: $KEYSTORE_PATH)"
      mkdir -p ${DATA_PATH}/ssl/
      keytool -genkey -noprompt \
        -alias jetty \
        -dname "CN=${HOSTNAME}, OU=Archiva, O=Archiva, L=Unknown, ST=Unknown, C=Unknown" \
        -keyalg RSA \
        -storepass "$STORE_AND_CERT_PASS"\
        -keypass "$STORE_AND_CERT_PASS"\
        -keystore ${KEYSTORE_PATH}
      keytool -genkey -noprompt -trustcacerts \
        -keyalg RSA \
        -alias "archiva" \
        -dname "CN=${HOSTNAME}, OU=Archiva, O=Archiva, L=Unknown, ST=Unknown, C=Unknown" \
        -keypass "$STORE_AND_CERT_PASS" \
        -keystore $KEYSTORE_PATH \
        -storepass "$STORE_AND_CERT_PASS"
    fi
    cp -f ${JETTY_CONF_PATH}/HTTPS_JETTY_CONF /tmp/.HTTPS_JETTY_CONF
    sed 's,{{KEYSTORE_PATH}},'"${KEYSTORE_PATH}"',' -i /tmp/.HTTPS_JETTY_CONF
    sed 's/{{STORE_AND_CERT_PASS}}/'"${STORE_AND_CERT_PASS}"'/' -i /tmp/.HTTPS_JETTY_CONF
    cd /tmp
    sed -i '/{{HTTPS_JETTY_CONF}}/r .HTTPS_JETTY_CONF' jetty.xml
    rm /tmp/.HTTPS_JETTY_CONF
  fi
  sed -i '/{{HTTPS_JETTY_CONF}}/d' jetty.xml
  mv jetty.xml ${DATA_PATH}/conf/jetty.xml
fi

i=0
# Add CA certs to the system if they are defined
if [[ -n "$CA_CERT" && -e "$CA_CERT" ]]
then
  CA_CERTS_TO_ADD[((i++))]="$CA_CERT"
fi

IFS="
"
if [[ -n "$CA_CERTS_DIR" && -e "$CA_CERTS_DIR" ]]
then
  for cert in `find $CA_CERTS_DIR -type f \( -iname \*.crt -o -iname \*.pem \)`
  do
    CA_CERTS_TO_ADD[((i++))]="$cert"
  done
fi

for (( i = 0; i < ${#CA_CERTS_TO_ADD[@]}; i++))
do
  echo "Importing ${CA_CERTS_TO_ADD[${i}]} to system keystore as ${CA_CERTS_TO_ADD[${i}]##*/}"
  keytool -import -trustcacerts -alias "${CA_CERTS_TO_ADD[${i}]##*/}"\
    -keystore /etc/ssl/certs/java/cacerts -file "${CA_CERTS_TO_ADD[${i}]}"\
    -storepass changeit -noprompt
done

/opt/archiva/bin/archiva console