#!/usr/bin/env sh
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

set \
    -o errexit \
    -o nounset

WORK_DIR="/gameapi"
RUN_DIR="$WORK_DIR/run"

if [ -z "$DEV_MYSQL_HOST" ] && [ -z "$PRO_MYSQL_HOST" ]; then
    echo "ERROR: MySQL host must be specified." && exit 1
fi
if [ -z "$DEV_MYSQL_USER" ] && [ -z "$PRO_MYSQL_USER" ]; then
    echo "ERROR: MySQL user must be specified." && exit 1
fi
if [ -z "$DEV_MYSQL_PASSWORD" ] && [ -z "$PRO_MYSQL_PASSWORD" ]; then
    echo "ERROR: MySQL password must be specified." && exit 1
fi
if [ -z "$DEV_MYSQL_DATABASE" ] && [ -z "$PRO_MYSQL_DATABASE" ]; then
    echo "ERROR: MySQL database must be specified." && exit 1
fi
if [ -z "$DEV_TIMEZONE" ] && [ -z "$PRO_TIMEZONE" ]; then
    echo "ERROR: Time zone must be specified." && exit 1
fi
if [ -z "$DEV_REDIS_HOST" ] && [ -z "$PRO_REDIS_HOST" ]; then
    echo "ERROR: Redis host must be specified." && exit 1
fi
if [ -z "$DEV_REDIS_PORT" ] && [ -z "$PRO_REDIS_PORT" ]; then
    echo "ERROR: Redis port must be specified." && exit 1
fi
if [ -z "$DEV_REDIS_DATABASE" ] && [ -z "$PRO_REDIS_DATABASE" ]; then
    echo "ERROR: Redis database must be specified." && exit 1
fi

if [ ! -d "$RUN_DIR/logs" ] || [ ! -d "$RUN_DIR/temp" ]; then
    mkdir -p \
        "$RUN_DIR/logs" \
        "$RUN_DIR/temp/client-body" \
        "$RUN_DIR/temp/proxy" \
        "$RUN_DIR/temp/fastcgi" \
        "$RUN_DIR/temp/uwsgi" \
        "$RUN_DIR/temp/scgi" 1>/dev/null
fi

chown -R nginx:nginx "$WORK_DIR" 1>/dev/null

# 数据库迁移所需
cp -f "$WORK_DIR/src/config/migrations.lua" "$WORK_DIR/run/migrations.lua"

# 运行配置文件
cp -f "$WORK_DIR/src/config/models.lua" "$WORK_DIR/run/models.lua"
cp -f "$WORK_DIR/src/config/mime.types" "$WORK_DIR/run/mime.types"
cp -f "$WORK_DIR/templates/nginx.conf" "$WORK_DIR/run/nginx.conf"

if ! command -v lapis >/dev/null 2>&1; then
    echo "ERROR: lapis is not installed"
    exit 1
fi

[ ! -s "$RUN_DIR/config.lua" ] && envsubst < "$WORK_DIR/templates/config.template.lua" > "$RUN_DIR/config.lua"

cd "$RUN_DIR" || { echo "ERROR: Failed to change directory!" && exit 1; }
if lapis migrate 2>/dev/null; then
    echo "Migration completed successfully!"
else
    echo "Migration failed!"
    exit 1
fi

if [ "$#" -eq 0 ]; then
    exec lapis server
else
    exec "$@"
fi