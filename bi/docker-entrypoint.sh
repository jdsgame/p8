#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025-2026 The JdsGame Authors. All rights reserved.
# Description: This script is used for the bi container runtime entry.

set -eu

WORK_DIR="/app"
MUST_CMD="envsubst aerich"

: "${DB_USER:?"Error: DB_USER missing"}"
: "${DB_PASSWORD:?"Error: DB_PASSWORD missing"}"
: "${DB_HOST:?"Error: DB_HOST missing"}"
: "${DB_PORT:?"Error: DB_PORT missing"}"
: "${DB_DATABASE:?"Error: DB_DATABASE missing"}"

for _cmd in $MUST_CMD; do
    if ! command -v "$_cmd" > /dev/null 2>&1; then
        echo "Error: $_cmd command not found!"
        exit 1
    fi
done

cd "$WORK_DIR" > /dev/null 2>&1 || {
    echo "Error: Failed to enter work path!"
    exit 1
}

[ ! -f ".env" ] && envsubst < templates/template.env > .env
[ ! -f "aerich_env.py" ] && envsubst < templates/aerich_env.template.py > aerich_env.py

if [ -n "$(find "$WORK_DIR/migrations/models" -mindepth 1 -print -quit 2> /dev/null)" ]; then
    aerich migrate
    aerich upgrade
else
    python3 manager.py initdb 2> /dev/null
    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db
fi

if [ "$#" -eq 0 ]; then
    exec python3 "$WORK_DIR/server.py"
else
    exec "$@"
fi
