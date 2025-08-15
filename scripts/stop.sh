#!/usr/bin/env bash
#
# Description: Adaptively resolves paths and stops multiple servers in parallel.
#
# Copyright (c) 2024-2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

# workflows:
# 1> 入口服停止 (login gate)
# 2> game服停止
# 3> 跨服服务停止
# 4> GM服停止
# 5> 中心服停止 (global and zk)
# 6> 日志服停止

set \
    -o nounset

readonly version='v0.2.2 (2025.05.16)'

_red() { echo -e "\033[91m$*\033[0m"; }
_green() { echo -e "\033[92m$*\033[0m"; }
_yellow() { echo -e "\033[93m$*\033[0m"; }
_purple() { echo -e "\033[95m$*\033[0m"; }
_cyan() { echo -e "\033[96m$*\033[0m"; }
_err_msg() { echo -e "\033[41m\033[1mError\033[0m $*"; }
_suc_msg() { echo -e "\033[42m\033[1mSuccess\033[0m $*"; }
_info_msg() { echo -e "\033[43m\033[1mInfo\033[0m $*"; }

# 各变量默认值
# https://github.com/koalaman/shellcheck/wiki/SC2155
STOP_PID="/tmp/stop.pid"
WORK_DIR="/data/tool"
APP_NAME="p8_app_server"
readonly STOP_PID WORK_DIR APP_NAME

if [ -f "$STOP_PID" ] && kill -0 "$(cat "$STOP_PID")" 2>/dev/null; then
    _err_msg "$(_red 'The script is running, please do not repeat the operation!')" && exit 1
fi

echo $$ > "$STOP_PID"

# 停服任务下发后, 信号捕获后的退出仅删除运行pid, 实际后台停服并行任务并未终止
_exit() {
    local RETURN_VALUE="$?"

    [ -f "$STOP_PID" ] && rm -f "$STOP_PID"
    exit "$RETURN_VALUE"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

# 清屏函数
clear_screen() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

# 运行校验
pre_check() {
    case "${1:-}" in
        --stop) : ;;
        *) echo "$(_cyan "当前为 $APP_NAME 停服") $(_yellow '按任意键继续')"; read -n 1 -s -r -p "" ;;
    esac

    clear_screen
    echo "$(_purple 'Current script version') $(_yellow "$version")"
    [ "$EUID" -ne 0 ] && { _err_msg "$(_red 'This script must be run as root!')"; exit 1; }
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')"; exit 1
    fi
}

# 统一停止入口
stop_server() {
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"
    local _DELAY="${3:-30s}" # Default flush delay is 30s

    # 子进程退出防止继续执行
    (
        if ! pgrep -f "$SERVER_DIR/$APP_NAME" >/dev/null 2>&1; then exit 0; fi # 进程存活校验
        cd "$SERVER_DIR" || { _err_msg "$(_red "$SERVER_NAME path error.")" ; exit 1; }
        [ ! -f server.sh ] && { _err_msg "$(_red "server.sh does not exist.")" ; exit 1; }
        [ ! -x server.sh ] && chmod +x server.sh
        ./server.sh flush && sleep "$_DELAY" && ./server.sh stop
        _suc_msg "$(_green "$SERVER_NAME The server has stopped.")"
    ) &
}

# 停止守护进程并清空运行日志
daemon_stop() {
    local DAEMON_FILE
    DAEMON_FILE='processcontrol-allserver.sh'

    if pgrep -f "$DAEMON_FILE" >/dev/null 2>&1; then
        pkill -9 -f "$DAEMON_FILE" >/dev/null 2>&1
        [ -f "$WORK_DIR/control.txt" ] && : > "$WORK_DIR/control.txt"
        [ -f "$WORK_DIR/dump.txt" ] && : > "$WORK_DIR/dump.txt"
        _suc_msg "$(_green "$DAEMON_FILE Process terminated, files cleared.")"
    else
        _info_msg "$(_cyan "$DAEMON_FILE The process is not running.")"
    fi
}

# 登录入口停止
entrance_stop() {
    if [ ! -d /data/server/login ] || [ ! -d /data/server/gate ]; then return; fi
    stop_server "login" "/data/server/login" "0s" # 0为存盘时间 $3, 无需存盘等待
    wait
    stop_server "gate" "/data/server/gate"
    wait

    _suc_msg "$(_green "Entrance stop success! \xe2\x9c\x93")"
}

# 游戏进程停止
game_stop() {
    local GAME_SERVER=()
    while IFS='' read -r ROW; do GAME_SERVER+=("$ROW"); done < <(find /data -maxdepth 1 -type d -name "server*[0-9]" -printf "%f\n" | sed 's/server//' | sort -n)

    if [ "${#GAME_SERVER[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GameServer list is empty, skip execution.')" && return; fi
    for num in "${GAME_SERVER[@]}"; do
        SERVER_NAME="server$num"
        SERVER_DIR="/data/$SERVER_NAME/game"
        stop_server "$SERVER_NAME" "$SERVER_DIR"
    done
    wait
    _suc_msg "$(_green "All GameServer stop success! \xe2\x9c\x93")"
}

# 跨服服务器停止
cross_stop() {
    local CROSS_SERVER=()
    while IFS='' read -r ROW; do CROSS_SERVER+=("$ROW"); done < <(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" -printf "%f\n" | sed 's/crossserver//' | sort -n)

    if [ "${#CROSS_SERVER[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The CrossServer list is empty, skip execution.')" && return; fi
    for num in "${CROSS_SERVER[@]}"; do
        SERVER_NAME="crossserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        stop_server "$SERVER_NAME" "$SERVER_DIR"
    done
    wait
    _suc_msg "$(_green "All CrossServer stop success! \xe2\x9c\x93")"
}

# GM服务器停止
gm_stop() {
    local GM_SERVER=()
    while IFS='' read -r ROW; do GM_SERVER+=("$ROW"); done < <(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" -printf "%f\n" | sed 's/gmserver//' | sort -n)

    if [ "${#GM_SERVER[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GMServer list is empty, skip execution.')" && return; fi
    for num in "${GM_SERVER[@]}"; do
        SERVER_NAME="gmserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        stop_server "$SERVER_NAME" "$SERVER_DIR"
    done
    wait
    _suc_msg "$(_green "All GMServer stop success! \xe2\x9c\x93")"
}

center_stop() {
    local BASE_PATH 
    local GLOBL_SERVER=()
    local ZK_SERVER=()
    readonly BASE_PATH='/data/center'

    if [ ! -d "$BASE_PATH" ]; then _info_msg "$(_cyan "The $BASE_PATH is empty, skip execution.")" && return; fi
    while IFS='' read -r ROW; do GLOBL_SERVER+=("$ROW"); done < <(find "$BASE_PATH" -maxdepth 1 -type d -name "global*[0-9]" -printf "%f\n" | sed 's/global//' | sort -n)
    while IFS='' read -r ROW; do ZK_SERVER+=("$ROW"); done < <(find "$BASE_PATH" -maxdepth 1 -type d -name "zk*[0-9]" -printf "%f\n" | sed 's/zk//' | sort -n)

    if [ "${#GLOBL_SERVER[@]}" -eq 0 ]; then
        _info_msg "$(_cyan 'The GlobalServer list is empty, skip execution.')"
        :
    else
        for num in "${GLOBL_SERVER[@]}"; do
            SERVER_NAME="global$num"
            SERVER_DIR="$BASE_PATH/$SERVER_NAME"
            stop_server "$SERVER_NAME" "$SERVER_DIR"
        done
        wait
        _suc_msg "$(_green "All GlobalServer stop success! \xe2\x9c\x93")"
    fi

    # ZK Server无需存盘, 传参$3跳过
    if [ "${#ZK_SERVER[@]}" -eq 0 ]; then
        _info_msg "$(_cyan 'The ZKServer list is empty, skip execution.')"
        :
    else
        for num in "${ZK_SERVER[@]}"; do
            SERVER_NAME="zk$num"
            SERVER_DIR="$BASE_PATH/$SERVER_NAME"
            stop_server "$SERVER_NAME" "$SERVER_DIR" "0s"
        done
        wait
        _suc_msg "$(_green "All ZKServer stop success! \xe2\x9c\x93")"
    fi
}

log_stop() {
    local LOG_SERVER=()
    while IFS='' read -r ROW; do LOG_SERVER+=("$ROW"); done < <(find /data -maxdepth 1 -type d -name "logserver*[0-9]" -printf "%f\n" | sed 's/logserver//' | sort -n)

    if [ "${#LOG_SERVER[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GMServer list is empty, skip execution.')" && return; fi
    for num in "${LOG_SERVER[@]}"; do
        SERVER_NAME="logserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        stop_server "$SERVER_NAME" "$SERVER_DIR"
    done
    wait
    _suc_msg "$(_green "All LogServer stop success! \xe2\x9c\x93")"
}

stop() {
    pre_check "$@"
    daemon_stop
    entrance_stop
    game_stop
    cross_stop
    gm_stop
    center_stop
    log_stop
}

stop "$@"