# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: Dockerfile to install essential PHP dependencies for the environment
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.
#
# References:
# https://blog.csdn.net/flysnownet/article/details/109387705

FROM php:8.1.32-fpm-alpine@sha256:0ac11fca1c9c79fa035c276e18580f3679f85b224e586e08ac26ef266b30db3d
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
