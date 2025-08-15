# Description: This dockerfile is used to build the basic operating environment of bi.
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

FROM m.daocloud.io/docker.io/library/python:3.9.20-alpine3.20
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