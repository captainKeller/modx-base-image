ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache

LABEL org.opencontainers.image.title="MODX Base Image" \
      org.opencontainers.image.description="A MODX development base image with Apache, PHP, MariaDB, Xdebug and automatic install." \
      org.opencontainers.image.source="https://github.com/captainKeller/modx-base-image" \
      org.opencontainers.image.documentation="https://github.com/captainKeller/modx-base-image/README.md" \
      org.opencontainers.image.licenses="GPL-2.0 license"

ARG MODX_VERSION=3.x

RUN apt-get update && apt-get install -y \
    git \
    mariadb-server \
    default-mysql-client \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libzip-dev \
    ftp \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        gd \
        zip \
        ftp

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

RUN a2enmod rewrite

RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/

RUN git clone https://github.com/modxcms/revolution.git modx \
    && cd modx \
    && git checkout ${MODX_VERSION} \
    && composer install --no-dev --no-interaction --prefer-dist \
    && cp _build/build.config.sample.php _build/build.config.php \
    && cp _build/build.properties.sample.php _build/build.properties.php \
    && php _build/transport.core.php \
    && rm -rf /var/www/html \
    && mv /var/www/modx /var/www/html

RUN rm /usr/bin/composer

WORKDIR /var/www/html

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN chown -R mysql:mysql /var/lib/mysql

RUN chown -R www-data:www-data /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
