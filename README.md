# xetusoss/archiva

An Apache Archiva image for simple standalone deployments.

---

# Tags and respective `Dockerfile` links

-   [`v2`, `v2.2.3`, `latest` (*v2/Dockerfile*)](https://github.com/xetus-oss/docker-archiva/blob/v2/Dockerfile)
-   [`2.2.3`, `v2-legacy` (*v2-legacy/Dockerfile*)](https://github.com/xetus-oss/docker-archiva/blob/v2-legacy/Dockerfile)

# Quick Reference

-    **Getting Help**:

     Please file issues in the [github repository](https://github.com/xetus-oss/docker-archiva/) if you find a problem with this image. For general help with Archiva, use the [Offical Resources](http://archiva.apache.org/get-involved.html)

-    **Contributing**:

     Pull requests/code copying are welcome! See the [Development](DEVELOPMENT.md) documentation for general guidelines.

-    **License**:

     This image, and Apache Archiva, are covered under the [Apache 2.0 License](LICENSE.txt)

# About Apache Archiva

[Apache Archiva](https://archiva.apache.org/) is maven-compatible artifact repository that is reasonably configurable and quite stable. 

# About `xetusoss/archiva`

This goal of this image is to be the easiest way to deploy a simple and reliable version of Apache Archiva. The key features of this image are:

* A data volume for ARCHIVA_BASE (`/archiva-data`)
* Easy `https` proxy support
* Container-managed `jetty.xml` configuration (which can be overwritten)
* Support for adding CA certificates to java environment
* A rational healthcheck (The docker `HEALTHCHECK` feature)

# Using this image

There are several ways to deploy an Apache Archiva environment with this image. The simpliest is to just start it up via the command line.

## Using the `docker` command

```console
docker run --name archiva -p 8080:8080 xetusoss/archiva:2.2.3-v2
```

## Deploying with `docker-compose`

The example below shows how to deploy archiva with a separate data volume using docker-compose. 

```yaml
version: '3.4'
services:
  archiva:
    image: xetusoss/archiva:2.2.3-v2
    volumes:
      - type: volume
        source: archiva-data-vol
        target: /archiva-data
    environment:
      SMTP_HOST: your-smtp-server

volumes:
  archiva-data-vol:
```

_For a more complete example of using docker-compose using ngnix as an https proxy, see [docker-compose.nginx-https.yaml](docker-compose.nginx-https.yaml)_

# Environment Variables

## `SMTP_HOST`, `SMTP_PORT`

Archiva requires access to an SMTP server for things like password reset emails. These variables are used by the managed `jetty.xml` configuration.

`SMTP_PORT` has a default value of 25.

_Note, there is no authentication support for SMTP in the auto-generated `jetty.xml`_

## `PROXY_BASE_URL`

It is recommended to deploy Archiva behind an HTTPS proxy. When using an HTTPS proxy, Archiva needs to be aware of the proxy's frontend url to operate properly.

Setting `PROXY_BASE_URL` will cause the container's entrypoint script to set all the needed java properties for Archiva to be aware of the proxy.

## `DB_TYPE`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`

The archiva user database can be stored in `mysql` instead of `derby` (the default). These environment variables can be used to configure the auto-generated `jetty.xml` to use a MySQL datasource. They are not necessary when using the default `derby` database.

See the [docker-compose.mysql.yaml](docker-compose.mysql.yaml) for a complete example of using MySQL.

## `JVM_MAX_MEM`, `JVM_EXTRA_OPTS`

These properties allow fine-tuned control over the JVM environment that archiva runs in. Unless you have specific needs, neither of these need to set.

## `JETTY_CONFIG_PATH`

If the container-managed `jetty.xml` file is not flexible enough for your deployment scenario, the `JETTY_CONFIG_PATH` environment variable can be used to manually specify a configuration file. 

# Adding CA certificates

If custom CA certificates are required, they can be automatically loaded into the java environment by mounting them in the `/certs` directory. All certificates must have a `.crt` or `.pem` extension.

# Why Archiva?

The Archiva project is not dead, but it's development is (very) slow. A reasonable question to ask is "Why bother when there are other tools like Artifactory?". We don't have a clear-cut answer for that, but here are some of the reasons you might consider Archiva.

1. It's a pure non-commercial product, maintained by Apache.
2. It's 'right-sized'. Archiva is small maven-style artifact repository that probably has all core features you'll need and nothing else. Flexible repository management, LDAP Authentication support, and a small UI. 
3. You have an existing Archiva repository to maintain.
4. It has this great docker image :-).

# Hints for running Archiva v2.x

Archiva 2.x suffers from a series quirks. Most of them can be reasonably avoided and here are some hints so your experience is smooth.

-   Admin UI: After refresh, navigate to a new section and back again

    While Archiva's REST endpoints are solid, the web UI has lots has lots of little annoyances. For example, if you refesh a page while signed in, you have to navigate to a *new* page before things work properly. 

-   Disable local user password expiration

    Local user password expiration wasn't carefully implemented in Archiva.  We recommend just disabling the feature.

-   If you've botched your configuration, edit the `archiva.xml`

# Change Log

## Image version 2 (Still Archiva 2.2.3)

After running everything in docker containers for the past several years, we've learned a few things about stateful applications in docker. Version 2 of this image is very different from the first one because it takes those lessons into account.

### Key Changes

-   __Direct java execution (container signals are supported)__
    The previous image version tried to stick closely to the recommended Archiva standalone deployment guide. However, this used the tanukisoft wrapper which made customizations difficult, had obsolete parameters, and caused the containers to not respect stop/kill signals.

    This version directly calls the java command solves all those issues.

-   __Jetty-based HTTPS support dropped, proxy support added__
    Running a proxy server in front of this container was a always better solution than managing HTTPS within jetty. This is espeicially true since the latest jetty version included Archiva's standalone release is an obsolete version.

-  __Custom CA certificate support simplified, fixed__
   The custom CA certificate support was simplified. All custom ca certificates must now be placed in a folder and mounted into `/certs`.

   Also, the container will spit out error messages when certificates are re-added to container's keystore.

### Upgrading from Image Version 1

A few manual steps may be required to upgrade to version 2 of the `xetusoss/archiva`, depending on your deployment configuration.

##### If you used the version 1 HTTPS support

To swap an existing container that used the built-in HTTPS support with one that uses proxy-based HTTPS support, create a new container with a version 2 image setting `PROXY_BASE_URL` environment variable and omit any of the following variables that you used previously:

* `SSL_ENABLED`
* `KEYSTORE_PATH`
* `KEYSTORE_PASS`
* `KEYSTORE_ALIAS`

For a simple example of how to setup an `nginx` proxy container for HTTPS support, see the [docker-compose.ngnix-https.yaml](docker-compose.ngnix-https.yaml) file.

##### If you manually managed the jetty configuration

If you manually managed the `jetty.xml` configuration in your previous container, use the new `JETTY_CONFIG_PATH` environment variable to point to your `jetty.xml` file

##### If you loaded custom CA certs into the container

Put the certificates into a folder using `.pem` or `.crt` extensions and mount the directory in the container under `/certs` .