# Archiva

An apache archiva 2.1.1 container designed for a simple standalone deployment. Key features are:

1. The configuration/data is truly externalized, allowing container replacement/upgrading (`/archiva-data`)
2. Configurable HTTPS support is included, with the ability to assign custom keystore/truststore
3. Linked container support for mysql/mariadb using the `database` alias

The configuration of the container was created following the support guide suggested by [Archiva standalone installation guide](http://archiva.apache.org/docs/2.1.1/adminguide/standalone.html).

## Quick Start

The command below will setup a running archiva container with externalized data/configuration

```
 docker run -d --name archiva -h archiva -d -p 8080:8080 -v /archiva_mnt:/archiva-data xetusoss/archiva
```

## Available Configuration Parameters

### Container parameters

The following parameters are used every time the container is replaced, regardless of the externalized configurations.

* `SSL_ENABLED`: Configure HTTPS support or not.
* `KEYSTORE_PATH`: The keystore path for jetty HTTPS certificate to use. Default is `/archiva-data/ssl/keystore`.
* `STORE_AND_CERT_PASS`: The keystore and certificate password to use. Default is `changeit`.

### Initialization parameters

The following parameters are only used to setup the initial configuration. Once the configuration has been established, theses are not used. All the parameters here map to configuration values in the archiva config.php.

See the [archiva documentation](https://doc.archiva.org/server/8.1/admin_manual/configuration_server/config_sample_php_parameters.html) for what each parameter does. The goal here is not to support every parameter, just those parameters
that you really would like to have in place before you get the the UI.

* `DB_TYPE` --> db type
    * default: derby
* `DB_NAME` --> db name
    * default: archiva_users
* `DB_USER` --> db user
    * default:
* `DB_PASS` --> db pass
    * default:
* `DB_HOST` --> db host
    * default:

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
  -e SSL_ENABLED=true -v /somepath/archiva_mnt:/archiva-data xetusoss/archiva
```

#### (3) Use a MYSQL db, with a linked container

The example below creates a archiva container with the linked mysql db. Please make sure `archiva_users` database created first, this database name can be changed using the `DB_NAME`.

```
docker run --name archiva -h archiva -p 443:8443\
  -v /somepath/archiva_mnt:/archiva-data --link mysql:database -e SSL_ENABLED=true xetusoss/archiva
```

#### (4) Use a MYSQL db, with an external host

The example below creates a archiva container using an external db. Please make sure `archiva_users` database created first, this database name can be changed using the `DB_NAME`.

```
docker run --name archiva -h archiva -p 443:8443\
  -v /somepath/archiva_mnt:/archiva-data -e DB_TYPE="mysql"\
  -e DB_HOST="db.example.com:3306"-e DB_USER="SOMEUSER"\
  -e DB_PASS="SOMEPASS" -e SSL_ENABLED=true xetusoss/archiva
```

## The archiva-data volume

The externalized data directory contains 4 directories: `data`, `logs`, `conf`, and `repositories`

 All directory are all standard in an archiva installation, so reference the archiva documentation for those.


Pull requests/code copying is welcome.