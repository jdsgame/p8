#!/bin/bash
#
# Copyright (c) 2021 Canonical Ltd.
# Copyright (c) 2025 Krzysztof Kozlowski <krzk@kernel.org>
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: GPL-2.0

set -eE

WORK_DIR="$(dirname "${BASH_SOURCE[0]}")"

for file in "$WORK_DIR"/*yml; do
    ansible-playbook -v --syntax-check "$file"
done

exit "$?"