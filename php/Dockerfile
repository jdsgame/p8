# Description: Dockerfile to install essential PHP dependencies for the environment
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# References:
# https://blog.csdn.net/flysnownet/article/details/109387705
#
# SPDX-License-Identifier: MIT

FROM php:8.1.32-fpm-alpine3.21
LABEL maintainer="honeok <i@honeok.com>"
RUN set -ex \
    && apk update \
    && apk add --no-cache tzdata \
    && wget -qO /usr/local/bin/install-php-extensions "https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions" \
    && chmod +x /usr/local/bin/install-php-extensions \
    && /usr/local/bin/install-php-extensions \
        bcmath \
        bz2 \
        calendar \
        exif \
        gd \
        gettext \
        gmp \
        ldap \
        mbstring \
        mysqli \
        mysqlnd \
        odbc \
        opcache \
        pdo_mysql \
        soap \
        shmop \
        sysvmsg \
        sysvsem \
        sysvshm \
        xml \
        xmlrpc \
        xsl \
    && printf '[PHP]\ndate.timezone = Asia/Shanghai\n' > /usr/local/etc/php/conf.d/timezone.ini \
    && rm -f /usr/local/bin/install-php-extensions \
    && rm -rf /var/cache/apk/*
ENV TZ=Asia/Shanghai