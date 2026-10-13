# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the basic operating environment of bi.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM python:3.10.0rc2-alpine@sha256:4079b6d8808672498a2731ca0ee8aa303d0d28bfcfd2caae24c1cf5cc7f1d25a
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
