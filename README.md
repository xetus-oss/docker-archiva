# xetusoss/archiva

An Apache Archiva image for simple standalone deployments.

---

# Tags

| Tag                                                                                        | Description                           |
|--------------------------------------------------------------------------------------------|---------------------------------------|
|[`v2`,`v2.2.4-1`, `latest`](https://github.com/xetus-oss/docker-archiva/blob/v2/Dockerfile) | Tracks the latest version of Archiva  |
|[`v2-snapshot`](https://github.com/xetus-oss/docker-archiva/blob/v2-snapshot/Dockerfile)    | Tracks v2 snapshot builds for Archiva |
|[`2.2.3`,`v2-legacy`](https://github.com/xetus-oss/docker-archiva/blob/v2-legacy/Dockerfile)| Legacy versions of this image         |

# Quick Reference

-    **Getting Help**:

     Please file issues in the [github repository](https://github.com/xetus-oss/docker-archiva/) if you find a problem with this image. For general help with Archiva, use the [Offical Resources](http://archiva.apache.org/get-involved.html)

-    **Contributing**:

     Pull requests/code copying are welcome! See the [Contributing](CONTRIBUTING.md) documentation for general guidelines.

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
docker run --name archiva -p 8080:8080 xetusoss/archiva
```

## Deploying with `docker-compose`

The example below shows how to deploy archiva with a separate data volume using docker-compose. 

```yaml
version: '3.4'
services:
  archiva:
    image: xetusoss/archiva:latest
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

## Deploying in Kubernetes

The easiest way to deploy this image in Kubernetes is to use the associated helm chart, [xetusoss-archiva](https://github.com/xetus-oss/helm-charts/tree/master/xetusoss-archiva). See the chart documentation for usage.

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

## `JVM_EXTRA_OPTS`, `MALLOC_ARENA_MAX`

Allow fine-tuned control over the JVM environment that archiva runs in, or set the MALLOC_ARENA_MAX. Unless you have specific needs, neither of these need to be set.

## `JETTY_CONFIG_PATH`

If the container-managed `jetty.xml` file is not flexible enough for your deployment scenario, the `JETTY_CONFIG_PATH` environment variable can be used to manually specify a configuration file. 

# Adding CA certificates

If custom CA certificates are required, they can be automatically loaded into the java environment by mounting them in the `/certs` directory. All certificates must have a `.crt` or `.pem` extension.

# Why Archiva?

The Archiva project is not dead, but it's development is (very) slow. A reasonable question to ask is "Why bother when there are other tools, like Artifactory?". We don't have a clear-cut answer for that, but here are some of the reasons you might consider Archiva.

1. It's a pure non-commercial product, maintained by Apache.
2. It's 'right-sized'. Archiva is small maven-style artifact repository that probably has all the core features you'll need and nothing else. It includes flexible repository management, LDAP Authentication support, a small UI, etc.
3. You have an existing Archiva repository to maintain.
4. It has this great docker image :-).

# Change Log

## `V2.2.4-1`

Resource configuration improvements from our experience running Archiva in k8s. Still using Archiva `v2.2.4`.

-   __Use `-XX:+UseContainerSupport`, retire `JVM_MAX_MEM`__
    Java 8u191 includes [improved support for docker containers](https://bugs.java.com/bugdatabase/view_bug.do?bug_id=JDK-8146115). This allows the java process to respect the container limits set by `cgroups`. Before this feature, the JVM would allocate resources for itself based on the host's total resources instead of the resources allocated to the container. The only way to avoid the situation was to set a series of related and complicated JVM options. With the improved container support, simply setting the container's resource limits is all that's needed. Due to this, we also retired support for the `JVM_MAX_MEM` enviroment variable. If specific tuning is required, users should use `JVM_EXTRA_OPTS`. 

-   __Set default `MALLOC_ARENA_MAX`__
    We now automatically export MALLOC_ARENA_MAX=2, unless specified by the user. Setting this option avoids the rare case of the jvm exceeding the container's memory limits.

-   __Use the `openjdk:8-jdk-alpine` image__
    There is no reason to continue using a more general-purpose container for Archiva. The alpine vairant saves about 200mbs of space with no drawbacks.

## `V2.2.4`

Support for [Archiva 2.2.4](http://archiva.apache.org/docs/2.2.4/release-notes.html), which is a minor patch release to `2.2.3`. `V2` has been updated to point to `v2.2.4`.

## `V2` (Still Archiva 2.2.3)

After running everything in docker containers for the past several years, we've learned a few things about stateful applications in docker. The `v2` tag of this image is very different from previous ones because it takes those lessons into account.

### Key Changes

-   __Direct java execution (container signals are supported)__
    The previous image version tried to stick closely to the recommended Archiva standalone deployment guide. However, this used the tanukisoft wrapper which made customizations difficult, had obsolete parameters, and caused the containers to not respect stop/kill signals.

    This version directly calls the java command solves all those issues.

-   __Jetty-based HTTPS support dropped, proxy support added__
    Running a proxy server in front of this container was a always better solution than managing HTTPS within jetty. This is espeicially true since the latest jetty version included Archiva's standalone release is an obsolete version.

-  __Custom CA certificate support simplified, fixed__
   The custom CA certificate support was simplified. All custom ca certificates must now be placed in a folder and mounted into `/certs`.

   Also, the container will spit out error messages when certificates are re-added to container's keystore.

### Upgrading from tag `2.2.3` and earlier

A few manual steps will be required to upgrade to the `v2` series of the `xetusoss/archiva`, depending on your deployment configuration.

##### Enable configuration migrations

Repository definitions created by images before the `v2` series used relative paths by default. These relative paths don't work properly in the `v2` series (see xetusoss/archiva#13).

The `v2` series image includes a script that can detect older configurations and upgrade them automatically, but the upgrade process...

1. Has the potential to break some custom configurations (though we don't know of any ATM)
2. Will cause Archiva to re-scan and re-index your entire repository.

To be on the safe side, we recommend making backups of these three paths under your data volume before performing the upgrade:

* `conf/archiva.xml`
* `data/jcr`
* `repositories/repositories`

When ready, launch a `v2` container with the `UPGRADE_PRE_V2` environment variable to `true` to enable the migration script.

##### If you used the version 1 HTTPS support

To swap an existing container that used the built-in HTTPS support with one that uses proxy-based HTTPS support, create a new container with a version 2 image setting the `PROXY_BASE_URL` environment variable and omit any of the following variables used previously:

* `SSL_ENABLED`
* `KEYSTORE_PATH`
* `KEYSTORE_PASS`
* `KEYSTORE_ALIAS`

For a simple example of how to setup an `nginx` proxy container for HTTPS support, see the [docker-compose.ngnix-https.yaml](docker-compose.ngnix-https.yaml) file.

##### If you manually managed the jetty configuration

If you manually managed the `jetty.xml` configuration in your previous container, use the new `JETTY_CONFIG_PATH` environment variable to point to your `jetty.xml` file

##### If you loaded custom CA certs into the container

Put the certificates into a folder using `.pem` or `.crt` extensions and mount the directory in the container under `/certs`.
