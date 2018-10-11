# Developing the Archiva Image

This is a pleasantly small image, that is easy to extend. This document covers the basics for local development and guidelines for contributing.

# Contributing

Pull requests are very welcome! For a pull request to be accepted, it must...

-  Pass all the local tests (`make test`)
-  Contain relevant documentation for the change.
-  Be backwards compatible, or clearly document the upgrade path.
-  Follow the guidelines listed here

# Guidelines

## The Docker Image

-   **Download/modify all external resources in `resource retriever.sh`**

-   **Always test checksums of downloaded files**

-   **Allow any managed files to be overwritten by the user**

## Archiva Management

-   **Use the standalone deployment of Archiva**
    Resist the urge to use a different servlet container! We want to track the offical Archiva project as closely as possible.

-   **Set values via java system properties, not the Archiva xml files**
    If adding support for application configuration, always use java
    system properties, rather that attempting to modify the `archiva.xml` file.

-   **Version-specific patches must not modify the user data**

# Tools

This repository comes with series of helpful tools for development. There are a few environment variables used by these tools:

* `TAG`: The image tag being produced.
* `HTTPS_PORT`: The HTTPS port to use when testing
* `REGISTRY`: A custom registry to push the image to

Start at the `Makefile` to learn more.

## Building

```
make build
```

As the name suggests, this will build a local version of the xetusoss/archiva image.

## Testing 

```
make test
```

There are a handful of scenario tests using bash scrips and docker-compose that ensure this image works as expected. These are used as a baseline to ensure the image is operating as expected.
