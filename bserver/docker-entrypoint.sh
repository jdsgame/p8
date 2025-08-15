#!/usr/bin/env sh
#
# Description: This script is used for the battle suit container runtime entry.
#
# Copyright (c) 2025 The p8 Ops Team
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

LUBAN_CONFIG_DIR="/bserver/config/luban"
LUBAN_CONFIG_DIR_TEMP="/bserver/config/luban_temp"

if [ -d "$LUBAN_CONFIG_DIR" ] && [ -z "$(ls -A "$LUBAN_CONFIG_DIR" 2>/dev/null)" ]; then
    command cp -rf "$LUBAN_CONFIG_DIR_TEMP"/* "$LUBAN_CONFIG_DIR/"
fi

if [ "$#" -eq 0 ]; then
    exec /bserver/bserver
else
    exec "$@"
fi