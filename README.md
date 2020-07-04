# xetusoss/archiva

An Apache Archiva image for simple standalone deployments.

[![](https://img.shields.io/docker/pulls/xetusoss/archiva.svg?label=pulls&logo=docker)](https://hub.docker.com/r/xetusoss/archiva/)
[![](https://img.shields.io/travis/xetus-oss/docker-archiva?label=Master%20Build)](https://travis-ci.org/xetus-oss/docker-archiva)
[![](https://img.shields.io/travis/xetus-oss/docker-archiva/v2-snapshot?label=v2-snapshot%20Build)](https://travis-ci.org/xetus-oss/docker-archiva)

---

# Tags

| Tag                                                                                        | Description                           |
|--------------------------------------------------------------------------------------------|---------------------------------------|
|[`v2`,`v2.2.5`, `latest`](https://github.com/xetus-oss/docker-archiva/blob/v2/Dockerfile)   | Tracks the latest version of Archiva  |
|[`v2-snapshot`](https://github.com/xetus-oss/docker-archiva/blob/v2-snapshot/Dockerfile)    | Tracks v2 snapshot builds for Archiva |
|[`2.2.3`,`v2-legacy`](https://github.com/xetus-oss/docker-archiva/blob/v2-legacy/Dockerfile)| Legacy versions of this image         |


> See the [Change Log](./CHANGELOG.md) for recent changes!

# Quick Reference

-    **Getting Help**:

     Please file issues in the [github repository](https://github.com/xetus-oss/docker-archiva/) if you find a problem with this image. For general help with Archiva, use the [Official Resources](http://archiva.apache.org/get-involved.html)

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

There are several ways to deploy an Apache Archiva environment with this image. The simplest is to just start it up via the command line.

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
2. It's 'right-sized'. Archiva is a small maven-style artifact repository that probably has all the core features you'll need and nothing else. It includes flexible repository management, LDAP Authentication support, a small UI, etc.
3. You have an existing Archiva repository to maintain.
4. It has this great docker image :-).
