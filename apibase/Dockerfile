# Description: This dockerfile is used to build the gameapi basic operating environment.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# References:
# https://github.com/luarocks/luarocks/wiki/Download
#
# SPDX-License-Identifier: MIT

ARG RESTY_IMAGE_BASE="honeok/openresty"
ARG RESTY_IMAGE_TAG="1.27.1.2-alpine-fat"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="honeok <i@honeok.com>"

RUN set -ex \
    && apk add --update --no-cache --virtual .build-deps \
        build-base \
        git \
    && apk add --no-cache \
        wget \
        mysql-dev \
    && /usr/local/openresty/luajit/bin/luarocks install ansicolors \
    && /usr/local/openresty/luajit/bin/luarocks install argparse \
    && /usr/local/openresty/luajit/bin/luarocks install date \
    && /usr/local/openresty/luajit/bin/luarocks install etlua \
    && /usr/local/openresty/luajit/bin/luarocks install lapis \
    && /usr/local/openresty/luajit/bin/luarocks install loadkit \
    && /usr/local/openresty/luajit/bin/luarocks install lpeg \
    && /usr/local/openresty/luajit/bin/luarocks install lua-cjson \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-hmac-ffi \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-http \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-mlcache \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-openssl \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-redis \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-requests \
    && /usr/local/openresty/luajit/bin/luarocks install luaossl \
    && /usr/local/openresty/luajit/bin/luarocks install luasocket \
    && /usr/local/openresty/luajit/bin/luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql \
    && /usr/local/openresty/luajit/bin/luarocks install net-url \
    && /usr/local/openresty/luajit/bin/luarocks install pgmoon \
    && apk del --no-network .build-deps \
    && rm -rf /var/cache/apk/*

ENV TZ=Asia/Shanghai