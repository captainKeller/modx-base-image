# MODX Base Docker Image

This repository provides a fully automated MODX development environment
inside a single Docker image.\
It includes Apache, PHP, MariaDB, automatic MODX
installation and Xdebug support.

The image is intended to be used as a base environment for developing
MODX Extras, allowing you to mount your component source code directly
into a running MODX instance using Docker Compose.

## Features

-   Automatic MariaDB initialization and user/database creation\
-   Automatic MODX installation on first startup\
-   Works on ARM and AMD64\
-   Xdebug installed \
-   Supports custom PHP and MODX versions\
-   Fully reproducible and self-contained development environment\
-   Can be published to GitHub Container Registry (GHCR)

## Building the Image

Build locally:

    docker build -t modx-base .

Build with custom PHP or MODX version:

    docker build \
      --build-arg PHP_VERSION=8.4 \
      --build-arg MODX_VERSION=3.x \
      -t modx-base .

## Running the Container

Start the container:

    docker run -p 8080:80 modx-base

After the container starts, MODX will be available at:

    http://localhost:8080/

During the first run, the container will:

1.  Initialize MariaDB\
2.  Create the MODX database and user\
3.  Build the MODX transport package (if using Git source)\
4.  Install MODX via the CLI installer

## Using This Image in Your MODX Extra Repository

Example `docker-compose.yml`:

``` yaml
services:
  modx:
    image: ghcr.io/<user>/<repo>/modx-base:latest
    ports:
      - "8080:80"
    volumes:
      - ./core/components:/var/www/html/core/components
      - ./assets/components:/var/www/html/assets/components
```

This mounts your component files into a running MODX instance for
development.

## Xdebug

Xdebug is installed by default for performance reasons.


## Environment Variables

  --------------------------------------------------------------------------
  Variable             Description                       Default
  -------------------- --------------------------------- -------------------
  MODX_DB_NAME         Database name                     modx

  MODX_DB_USER         Database user                     modx

  MODX_DB_PASSWORD     Database password                 modx

  MODX_DB_PREFIX       Table prefix                      modx\_

  MODX_ADMIN_USER      MODX manager admin username       admin

  MODX_ADMIN_PASS      MODX manager admin password       admin12345

  MODX_ADMIN_EMAIL     MODX manager admin email          admin@example.com

  MODX_HTTP_HOST       Hostname used for MODX config     localhost
  --------------------------------------------------------------------------

