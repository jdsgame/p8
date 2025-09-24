#!/usr/bin/env bash
#
# Description: This script is used to quickly batch-replace the main program in a production environment.
#
# Copyright (c) 2025 honeok <i@honeok.com>
# SPDX-License-Identifier: MIT

set -eEuo pipefail

START_TIME="$(date +%s 2>/dev/null)"

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# 设置系统UTF-8语言环境
UTF8_LOCALE="$(locale -a 2>/dev/null | grep -iEm1 "UTF-8|utf8")"
[ -n "$UTF8_LOCALE" ] && export LC_ALL="$UTF8_LOCALE" LANG="$UTF8_LOCALE" LANGUAGE="$UTF8_LOCALE"

# 自定义彩色字体
_red() { printf "\033[91m%b\033[0m\n" "$*"; }
_green() { printf "\033[92m%b\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%b\033[0m\n" "$*"; }
_cyan() { printf "\033[96m%b\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %b\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %b\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %b\n" "$*"; }

# 各变量默认值
readonly SCRIPT_VER="v25.9.24"
OS_INFO="$(grep '^PRETTY_NAME=' /etc/os-release | awk -F'=' '{print $NF}' | sed 's#"##g')"
readonly SCRIPT_NAME="replace.sh"
APP_NAME="p8_app_server"
REPLACE_CORE="/data/update/$APP_NAME" # 新执行程序

clear() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

die() {
    _err_msg >&2 "$(_red "$@")"; exit 1
}

show_logo() {
    _yellow "
                __
  _______ ___  / ___ ________
 / __/ -_/ _ \/ / _ \`/ __/ -_)
/_/  \__/ .__/_/\_,_/\__/\__/
       /_/
"
    echo -e "$(_green "System:") \t$(_green "$OS_INFO")"
    echo "$(_cyan "Script Version: $SCRIPT_VER") $(_yellow "\xF0\x9F\xA7\xA9")"
    echo
}

check_root() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "This script must be run as root!"
    fi
}

usage() {
    tee <<EOF
$(_red "Usage:") $SCRIPT_NAME [Zone id] [Sleep time]

EOF
    exit 1
}

# 运行预检
check_pre() {
    local SERVER_NUM="$1" # 区服id
    local TARGET_PATH
    TARGET_PATH="/data/server$SERVER_NUM/game/$APP_NAME"

    if [ ! -f "$REPLACE_CORE" ]; then
        die "The replace executable does not exist."
    fi
    if [ ! -d "/data/server$SERVER_NUM/game" ]; then
        die "The target directory does not exist."
    fi
    # 文件哈希比对
    if [[ "$(sha256sum "$REPLACE_CORE" 2>/dev/null | awk '{print $1}')" == "$(sha256sum "$TARGET_PATH" 2>/dev/null | awk '{print $1}')" ]]; then
        _info_msg "$(_yellow "File hash equality!")"
        exit 0
    fi
    if [ ! -x "$REPLACE_CORE" ]; then
        if ! chmod +x "$REPLACE_CORE" >/dev/null 2>&1; then
            die "Failed to make $REPLACE_CORE executable."
        fi
    fi
}

# 停止守护进程
stop_daemon() {
    if ! pgrep -f "processcontrol-allserver.sh" >/dev/null 2>&1; then
        _info_msg "$(_yellow "Daemon not found, skip.")"
        return
    fi

    pkill -9 -f "processcontrol-allserver.sh" >/dev/null 2>&1

    # 给进程退出足够的时间
    for ((i=1; i<=3; i++)); do
        if ! pgrep -f "processcontrol-allserver.sh" >/dev/null 2>&1; then
            _suc_msg "$(_green "Daemon kill completed!")"
            return 0
        fi
        sleep 1
    done

    # deadline
    die "Daemon kill fail."
}

# 替换执行档
replace() {
    local SERVER_NUM="$1" # 区服id
    local SLEEP_TIME="$2"
    local TARGET_PATH PID
    TARGET_PATH="/data/server$SERVER_NUM/game/$APP_NAME"

    if ! cd "/data/server$SERVER_NUM/game" >/dev/null 2>&1; then
        die "Unable to access folder."
    fi

    _info_msg "$(_yellow "Saving and shutdown") $(_cyan "server$SERVER_NUM")$(_yellow ".")"
    (./server.sh flush >/dev/null 2>&1 \
    && sleep "$SLEEP_TIME" \
    && ./server.sh stop >/dev/null 2>&1) &
    wait

    _info_msg "$(_yellow "Overwrite old execution program.")"
    for ((i=1; i<=3; i++)); do
        if command cp -f "$REPLACE_CORE" "$TARGET_PATH" >/dev/null 2>&1; then
            break
        fi
        [ "$i" -eq 3 ] && die "Failed to copy executable."
        sleep 1
    done

    sleep 2
    ./server.sh start

    _suc_msg "$(_cyan "server$SERVER_NUM") $(_green "completed!")"

    # 等待程序完全启动再过滤pid
    for ((i=1; i<=3; i++)); do
        PID="$(pgrep -f "/data/server$SERVER_NUM/game/$APP_NAME" 2>/dev/null)"
        if [[ -n "$PID" && "$PID" =~ ^[0-9]+$ ]]; then
            break
        fi
        [ "$i" -eq 3 ] && die "Failed to find process id."
        sleep 0.5
    done
    echo
    ps -p "$PID" -o user,pid,%cpu,%mem,vsz,rss,tty,stat,start,time,command
}

_end_msg() {
    local END_TIME TIME_COUNT MIN SEC
    END_TIME="$(date +%s 2>/dev/null)"

    TIME_COUNT=$((END_TIME - START_TIME))
    if [ "$TIME_COUNT" -gt 60 ]; then
        MIN=$((TIME_COUNT / 60))
        SEC=$((TIME_COUNT % 60))
        _info_msg "$(_yellow "$SCRIPT_NAME completed in") $(_cyan "$MIN") $(_yellow "min") $(_cyan "$SEC") $(_yellow "sec")"
    else
        _info_msg "$(_yellow "$SCRIPT_NAME completed in") $(_cyan "$TIME_COUNT") $(_yellow "sec")"
    fi
}

# 主程序运行 1/2
clear
show_logo
check_root

# 主程序运行 2/2
if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
    usage
else
    check_pre "$1"
    stop_daemon
    replace "$1" "${2:-10}"
    _end_msg
fi
