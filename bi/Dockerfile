# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the bi image in container.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM registry.cn-chengdu.aliyuncs.com/jdsgame/bi-base:v26.2.4-f4a2d69@sha256:f9bf0b58c40cca67f4d4481428aae8009ac6a7c26f8e9dcb9a9e5a061d7fdf34
WORKDIR /app
COPY . .
RUN set -ex \
    && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && rm -f docker-entrypoint.sh .env aerich_env.py \
    && rm -rf /var/cache/apk/* logs/*
EXPOSE 8000
ENV TZ=Asia/Shanghai
ENTRYPOINT ["/docker-entrypoint.sh"]
