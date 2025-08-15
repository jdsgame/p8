#!/usr/bin/env sh
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

ports="80 81"

for port in $ports; do
    count=0

    until nc -z -w 5 127.0.0.1 "$port"; do
        count=$(( count + 1 ))

        echo "Health check failed. Retrying ($count/2)"
        if [ $count -ge 2 ]; then
            echo "Service on port $port is not responding, exiting!"
            exit 1
        fi
        sleep 10
    done
    echo "Service on port $port is healthy!"
done
exit 0