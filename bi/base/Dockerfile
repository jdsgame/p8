# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the basic operating environment of bi.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM python:3.9.25-alpine@sha256:c99b6eb43b3ac4d750db3d6e8b22268d5ea9a99deead7218ce3deda7f2ca029c
COPY . .
ENV PIP_ROOT_USER_ACTION=ignore
RUN set -ex \
    && apk add --no-cache --update \
        gcc \
        gettext-envsubst \
        libffi-dev \
        musl-dev \
        python3-dev \
        tzdata \
    && python3 -m pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt \
    && rm -rf /var/cache/apk/*
