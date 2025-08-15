#!/usr/bin/env sh
#
# Description: This script is used for the bi container runtime entry.
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

set \
    -o errexit \
    -o nounset

WORK_DIR="/bi"
MUST_CMD="envsubst aerich"

: "${DB_USER?error: DB_USER missing}"
: "${DB_PASSWORD?error: DB_PASSWORD missing}"
: "${DB_HOST?error: DB_HOST missing}"
: "${DB_PORT?error: DB_PORT missing}"
: "${DB_DATABASE?error: DB_DATABASE missing}"

for _cmd in $MUST_CMD; do
    if ! command -v "$_cmd" >/dev/null 2>&1; then
        echo "ERROR: $_cmd command not found!"; exit 1
    fi
done

cd "$WORK_DIR" || { echo "error: Failed to enter work path!"; exit 1; }

[ ! -f ".env" ] && envsubst < templates/template.env > .env
[ ! -f "aerich_env.py" ] && envsubst < templates/aerich_env.template.py > aerich_env.py

if [ -n "$(find "$WORK_DIR/migrations/models" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    aerich migrate
    aerich upgrade
else
    python3 manager.py initdb 2>/dev/null
    aerich init -t aerich_env.TORTOISE_ORM
    aerich init-db
fi

if [ "$#" -eq 0 ]; then
    exec python3 "$WORK_DIR/server.py"
else
    exec "$@"
fi