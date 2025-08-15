# Description: This dockerfile is used to build the gameapi container operating environment.
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

FROM registry.cn-chengdu.aliyuncs.com/havario/api-base:v0.0.6-alpine
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
ENTRYPOINT [ "/docker-entrypoint.sh" ]
HEALTHCHECK --interval=30s --retries=2 --timeout=5s --start-period=10s \
    CMD /usr/local/bin/healthcheck.sh