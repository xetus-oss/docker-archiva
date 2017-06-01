# Archiva

An apache archiva 2.2.3 container designed for a simple standalone deployment. Key features are:

1. The configuration/data is truly externalized, allowing container replacement/upgrading (`/archiva-data`)
2. Configurable HTTPS support is included, with the ability to assign custom keystore
3. Linked container support for mysql/mariadb using the `db` alias. 
4. Automatic installation of CA certificates into the container

The configuration of the container was created following the support guide suggested by [Archiva standalone installation guide](http://archiva.apache.org/docs/2.1.1/adminguide/standalone.html).

## Quick Start

The command below will setup a running archiva container with externalized data/configuration

```
 docker run -d --name archiva -h archiva -d -p 8080:8080 -v /archiva_mnt:/archiva-data xetusoss/archiva
```

## Available Configuration Parameters

* `SSL_ENABLED`: Configure HTTPS support or not.
* `KEYSTORE_PATH`: The keystore path for jetty HTTPS certificate to use. Default is `/archiva-data/ssl/keystore`.
* `KEYSTORE_PASS`: The keystore and certificate password to use. Default is `changeit`.
* `KEYSTORE_ALIAS`: The certificate alias to use. Default is `archiva`.
* `CA_CERT` and `CA_CERTS_DIR`: Specify the CA cert(Or the path to dir store multiply certs) to install into system keystore.
* `DB_TYPE`: The database type, either `mysql` or `derby`. Default is `derby`.
* `USERS_DB_NAME`: Only used if `DB_TYPE=mysql`, the database name for the `users` db. Default is `archiva_users`.
* `DB_USER`: Only used if `DB_TYPE=mysql`, the user to make the db connection with. Default is `archiva`.
* `DB_PASS`: Only used if `DB_TYPE=mysql`, the db user's password. Default is `archiva`.
* `DB_HOST`:  Only used if `DB_TYPE=mysql`, the db hostname or IP. Default is `db`.
* `DB_PORT`:  Only used if `DB_TYPE=mysql`, the db port to connect to. Default is `3306`.

## Examples

#### (1) HTTPS Support (generated certificate)
Make sure /somepath/archiva_mnt exists

```
 docker run --name archiva -h archiva -d -p 443:8443\
  -e SSL_ENABLED=true -v /somepath/archiva_mnt:/archiva-data xetusoss/archiva
```
#### (2) HTTPS Support (custom/assigned certificate included)


Copy the custom keystore in data mount under `ssl/keystoer`. The locations can be changed using the `KEYSTORE_PATH`.

```
 docker run --name archiva -h archiva -d -p 443:8443\
  -e SSL_ENABLED=true -e KEYSTORE_PASS="mypass" -v /somepath/archiva_mnt:/archiva-data xetusoss/archiva
```

#### (3) Use a MYSQL db, with a linked container

The example below creates a archiva container with the linked mysql db. Please make sure `archiva_users` database created first, these database name can be changed using `USERS_DB_NAME`.

```
docker run --name archiva -h archiva -p 443:8443\
  -v /somepath/archiva_mnt:/archiva-data --link mysql:db -e SSL_ENABLED=true xetusoss/archiva
```

#### (4) Use a MYSQL db, with an external host

The example below creates a archiva container using an external db. Please make sure `archiva_users` database created first, these database name can be changed using `USERS_DB_NAME`.

```
docker run --name archiva -h archiva -p 443:8443\
  -v /somepath/archiva_mnt:/archiva-data -e DB_TYPE="mysql"\
  -e DB_HOST="db.example.com"-e DB_USER="SOMEUSER"\
  -e DB_PASS="SOMEPASS" -e SSL_ENABLED=true xetusoss/archiva
```

## The archiva-data volume

The externalized data directory contains 4 directories: `data`, `logs`, `conf`, and `repositories`

 All directory are all standard in an archiva installation, so reference the archiva documentation for those.

Pull requests/code copying are welcome.
