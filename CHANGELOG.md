# Change Log

## `V2.2.5`

Updated to Archiva `v2.2.5` which includes a fix for [CVE-2020-9495](https://www.mail-archive.com/dev@archiva.apache.org/msg02821.html).

## `V2.2.4-1`

Resource configuration improvements from our experience running Archiva in k8s. Still using Archiva `v2.2.4`.

-   __Use `-XX:+UseContainerSupport`, retire `JVM_MAX_MEM`__
    Java 8u191 includes [improved support for docker containers](https://bugs.java.com/bugdatabase/view_bug.do?bug_id=JDK-8146115). This allows the java process to respect the container limits set by `cgroups`. Before this feature, the JVM would allocate resources for itself based on the host's total resources instead of the resources allocated to the container. The only way to avoid the situation was to set a series of related and complicated JVM options. With the improved container support, simply setting the container's resource limits is all that's needed. Due to this, we also retired support for the `JVM_MAX_MEM` environment variable. If specific tuning is required, users should use `JVM_EXTRA_OPTS`. 

-   __Set default `MALLOC_ARENA_MAX`__
    We now automatically export MALLOC_ARENA_MAX=2, unless specified by the user. Setting this option avoids the rare case of the jvm exceeding the container's memory limits.

-   __Use the `openjdk:8-jdk-alpine` image__
    There is no reason to continue using a more general-purpose container for Archiva. The alpine variant saves about 200mbs of space with no drawbacks.

## `V2.2.4`

Support for [Archiva 2.2.4](http://archiva.apache.org/docs/2.2.4/release-notes.html), which is a minor patch release to `2.2.3`. `V2` has been updated to point to `v2.2.4`.

## `V2` (Still Archiva 2.2.3)

After running everything in docker containers for the past several years, we've learned a few things about stateful applications in docker. The `v2` tag of this image is very different from previous ones because it takes those lessons into account.

### Key Changes

-   __Direct java execution (container signals are supported)__
    The previous image version tried to stick closely to the recommended Archiva standalone deployment guide. However, this used the tanukisoft wrapper which made customizations difficult, had obsolete parameters, and caused the containers to not respect stop/kill signals.

    This version directly calls the java command, which solves all those issues.

-   __Jetty-based HTTPS support dropped, proxy support added__
    Running a proxy server in front of this container was a always better solution than managing HTTPS within jetty. This is especially true since the latest jetty version included Archiva's standalone release is an obsolete version.

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

For a simple example of how to set up an `nginx` proxy container for HTTPS support, see the [docker-compose.ngnix-https.yaml](docker-compose.ngnix-https.yaml) file.

##### If you manually managed the jetty configuration

If you manually managed the `jetty.xml` configuration in your previous container, use the new `JETTY_CONFIG_PATH` environment variable to point to your `jetty.xml` file

##### If you loaded custom CA certs into the container

Put the certificates into a folder using `.pem` or `.crt` extensions and mount the directory in the container under `/certs`.
