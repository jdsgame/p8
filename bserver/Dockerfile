# syntax=docker/dockerfile:1
# SPDX-License-Identifier: MIT
#
# Description: This dockerfile is used to build the containerized combat suit.
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.

FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /bserver
COPY . .
RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.nju.edu.cn/g' /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk add --no-cache \
        libstdc++ \
        libc6-compat \
        tzdata \
    && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && cp -f templates/App.template.json config/App.json \
    && rm -f docker-entrypoint.sh \
    && rm -rf config/luban_temp \
    && rm -rf /var/cache/apk/* templates logs BattleSimulator \
    && mkdir -p logs BattleSimulator config/luban_temp \
    && cp -rf config/luban/* config/luban_temp/
ENV TZ=Asia/Shanghai
EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint.sh"]
