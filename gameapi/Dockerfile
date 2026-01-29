# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the gameapi container operating environment.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM registry.cn-chengdu.aliyuncs.com/havario/api-base:v0.0.6-alpine@sha256:df86009126dea7ec8bec91e2fde6cb1c7ff61ed2860f2d1537e9a8205e9efe24
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /gameapi
COPY . .
RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.nju.edu.cn/g' /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk add --no-cache \
        gettext-envsubst \
    && chmod +x build.sh && ./build.sh \
    && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && install -m 755 healthcheck.sh /usr/local/bin/healthcheck.sh \
    && rm -f build.sh docker-entrypoint.sh healthcheck.sh \
    && rm -rf /var/cache/apk/* /tmp/* \
    && ln -sf /dev/stdout /gameapi/run/logs/access.log \
    && ln -sf /dev/stderr /gameapi/run/logs/error.log
ENV LAPIS_ENVIRONMENT=development
ENTRYPOINT ["/docker-entrypoint.sh"]
HEALTHCHECK --interval=30s --retries=2 --timeout=5s --start-period=10s \
    CMD /usr/local/bin/healthcheck.sh
