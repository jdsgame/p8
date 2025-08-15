#!/usr/bin/env bash
#
# Description: This script is used to traverse the database for full backup.
#
# Copyright (c) 2024-2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

set -e

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %s\n" "$*"; }

# 各变量默认值
MYSQLBAK_PID="/tmp/mysqlbak.pid"
WORKDIR="/data/dbback"
TEMPDIR="/data/dbback/temp"

# mysqldump默认备份参数
# --no-defaults: MySQL命令行工具如 mysqldump mysql忽略默认的配置文件.
# --single-transaction: 启动一个单一事务来确保导出数据的一致性, 而不锁定整个数据库.
# --set-gtid-purged=OFF: 不会在导出的SQL文件中包含用于主从复制的全局唯一事务标识符.
BAK_PARAMETERS=(--no-defaults --single-transaction --set-gtid-purged=OFF)

if [ -f "$MYSQLBAK_PID" ] && kill -0 "$(cat "$MYSQLBAK_PID")" 2>/dev/null; then
    _err_msg "$(_red 'The script seems to be running, please do not run it again!')"; exit 1
fi

# 将当前进程写入pid防止并发执行导致冲突
echo $$ > "$MYSQLBAK_PID"

_exit() {
    local RETURN_VALUE="$?"

    [ -f "$MYSQLBAK_PID" ] && rm -f "$MYSQLBAK_PID" >/dev/null 2>&1
    exit "$RETURN_VALUE"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

error_and_exit() {
    _err_msg "$(_red "$@")" >&2 && exit 1
}

# 安全清屏函数
clear_screen() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

# 用于检查命令是否存在
_is_exists() {
    local _CMD="$1"
    if command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif type "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

pre_check() {
    local -a DEPEND_PKG

    DEPEND_PKG=("mysql" "mysqldump")
    if [ "$EUID" -ne 0 ]; then
        error_and_exit "This script must be run as root!"
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        error_and_exit "This script needs to be run with bash, not sh!"
    fi
    for pkg in "${DEPEND_PKG[@]}"; do
        if ! _is_exists "$pkg"; then
            error_and_exit "$pkg command does not exist."
        fi
    done
    { env | grep -qi '^MYSQL'; } || error_and_exit "No valid mysql variable found."
}

before_run() {
   local GAMEDB_DIR="$1"
   { [ -n "$GAMEDB_DIR" ] && [ ! -d "$GAMEDB_DIR" ]; } && mkdir -p "$GAMEDB_DIR" >/dev/null 2>&1
   [ ! -d "$TEMPDIR" ] && mkdir -p "$TEMPDIR" >/dev/null 2>&1
}

# 用于将临时路径的sql文件移动到最终存储路径
after_run() {
    local GAMEDB_DIR="$1"
    { [ -n "$GAMEDB_DIR" ] && cd "$GAMEDB_DIR"; } || error_and_exit "The path is incorrect or there is no permission."
    rm -rf "${GAMEDB_DIR:?Error: Game directory not set}"/* >/dev/null 2>&1
    mv -f "$TEMPDIR"/* "$GAMEDB_DIR" >/dev/null 2>&1
    rm -rf "${TEMPDIR:?Error: Temp directory not set}" >/dev/null 2>&1
}

gamedb1_bak() {
    local GAMEDB_DIR
    local -A GAMEDB
    local -a DATABASES

    # 定义备份sql存储路径
    GAMEDB_DIR="$WORKDIR/gamedb1"
    before_run "$GAMEDB_DIR"
    # 定义关联数组用于存储数据库连接信息, 值来自环境变量 /etc/profile.d/mysql.sh
    GAMEDB=(
        ["MYSQL_USER_GAMEDB1"]="$MYSQL_USER_GAMEDB1"
        ["MYSQL_PASSWD_GAMEDB1"]="$MYSQL_PASSWD_GAMEDB1"
        ["MYSQL_PORT_GAMEDB1"]="$MYSQL_PORT_GAMEDB1"
        ["MYSQL_IP_GAMEDB1"]="$MYSQL_IP_GAMEDB1"
    )

    while read -r DB; do
        DATABASES+=("$DB")
    done < <(mysql -h "${GAMEDB[MYSQL_IP_GAMEDB1]}" \
            -u "${GAMEDB[MYSQL_USER_GAMEDB1]}" \
            -p"${GAMEDB[MYSQL_PASSWD_GAMEDB1]}" \
            -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(Database|information_schema|mysql|performance_schema|sys)")

    # 执行备份
    for database in "${DATABASES[@]}"; do
        /usr/bin/mysqldump "${BAK_PARAMETERS[@]}" \
        -h "${GAMEDB[MYSQL_IP_GAMEDB1]}" \
        -P "${GAMEDB[MYSQL_PORT_GAMEDB1]}" \
        -u "${GAMEDB[MYSQL_USER_GAMEDB1]}" \
        -p"${GAMEDB[MYSQL_PASSWD_GAMEDB1]}" \
        -R "$database" > "$TEMPDIR/${database}_$(LC_TIME="en_DK.UTF-8" TZ=Asia/Shanghai date +%Y%m%d%H%M%S).sql" 2>/dev/null
        _suc_msg "$(_green "$database Backup Complete!")" || error_and_exit "$database Backup fail."
    done
    after_run "$GAMEDB_DIR"
}

mysqlbak() {
    clear_screen
    pre_check
    gamedb1_bak
}

mysqlbak