#!/usr/bin/env sh
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

count=0

until nc -z -w 5 127.0.0.1 80; do
    count=$(( count + 1 ))

    echo "Health check failed. Retrying ($count/2)"
    if [ $count -ge 2 ]; then
        echo "Service on port 80 is not responding, exiting!"
        exit 1
    fi
    sleep 10
done

echo "Service on port 80 is healthy!"
exit 0