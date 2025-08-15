# Description: This dockerfile is used to build the bi image in container.
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

FROM registry.cn-chengdu.aliyuncs.com/havario/bi-base:v1.0.9-alpine
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /bi
COPY . .
RUN set -ex \
    && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
    && rm -f docker-entrypoint.sh .env aerich_env.py \
    && rm -rf /var/cache/apk/* logs/*
EXPOSE 8000
ENTRYPOINT [ "/docker-entrypoint.sh" ]