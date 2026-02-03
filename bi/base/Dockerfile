# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the basic operating environment of bi.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM python:3.9.25-alpine@sha256:c99b6eb43b3ac4d750db3d6e8b22268d5ea9a99deead7218ce3deda7f2ca029c
LABEL maintainer="honeok <i@honeok.com>"
COPY requirements.txt .
RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.nju.edu.cn/g' /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk add --no-cache \
        gcc \
        gettext-envsubst \
        libffi-dev \
        musl-dev \
        python3-dev \
        tzdata \
    && python3 -m pip install --no-cache-dir -r requirements.txt -i https://mirrors.nju.edu.cn/pypi/web/simple/ --trusted-host mirrors.nju.edu.cn \
    && rm -f requirements.txt \
    && rm -rf /var/cache/apk/*
ENV TZ=Asia/Shanghai
