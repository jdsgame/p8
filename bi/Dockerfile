# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the bi image in container.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:v1.0.9-alpine@sha256:769bedea6c153dd0154dc1dd71b48eb89f239c476a155872832429bca777fb6b
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /bi
COPY . .
RUN set -ex \
    && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && rm -f docker-entrypoint.sh .env aerich_env.py \
    && rm -rf /var/cache/apk/* logs/*
EXPOSE 8000
ENTRYPOINT ["/docker-entrypoint.sh"]
