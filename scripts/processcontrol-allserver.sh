#!/usr/bin/env bash
# vim:sw=4:ts=4:et
#
# Description: server backend resident daemon for monitoring and management.
#
# Copyright (c) 2024-2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

# 当前脚本版本号
readonly VERSION='v0.1.6 (2025.04.30)'

# 各变量默认值
PROCESS_PID='/tmp/process.pid'
LOG_DIR='/data/logbak'
WORK_DIR='/data/tool'
APP_NAME='p8_app_server'
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
readonly PROCESS_PID LOG_DIR WORK_DIR APP_NAME UA_BROWSER

declare -a CURL_OPTS=(--max-time 5 --retry 1 --retry-max-time 10)

send_message() {
    local EVENT="$1"
    local CLOUDFLARE_API='www.qualcomm.cn'
    local PUBLIC_IP CUR_TIME COUNTRY OS_INFO CPU_ARCH

    PUBLIC_IP=$(curl -A "$UA_BROWSER" "${CURL_OPTS[@]}" -fsL "http://$CLOUDFLARE_API/cdn-cgi/trace" | grep -i '^ip=' | cut -d'=' -f2 | xargs)
    CUR_TIME=$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')
    COUNTRY=$(curl -A "$UA_BROWSER" "${CURL_OPTS[@]}" -fsL "http://$CLOUDFLARE_API/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)
    OS_INFO=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    CPU_ARCH=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}')

    (
        curl -fsL -k -X POST "https://p8.119611.xyz/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$EVENT $PUBLIC_IP\",\"timestamp\":\"$CUR_TIME\",\"country\":\"$COUNTRY\",\"os_info\":\"$OS_INFO\",\"cpu_arch\":\"$CPU_ARCH\"}" \
        >/dev/null 2>&1
    ) & disown
}

pre_check() {
    # 确保守护进程唯一
    if [ -f "$PROCESS_PID" ] && kill -0 "$(cat "$PROCESS_PID")" 2>/dev/null; then
        echo 'The script is running, please do not repeat the operation!' >> "$WORK_DIR/control.txt" && exit 1
    fi
    echo $$ > "$PROCESS_PID"
    # 确保root用户运行
    if [ "$EUID" -ne 0 ]; then
        echo 'This script must be run as root!' >> "$WORK_DIR/control.txt" && exit 1
    fi
    # 确保使用bash运行而不是sh
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        echo 'This script needs to be run with bash, not sh!' >> "$WORK_DIR/control.txt" && exit 1
    fi
    # 创建运行必备文件夹
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR" 2>/dev/null
    [ ! -d "$WORK_DIR" ] && mkdir -p "$WORK_DIR" 2>/dev/null
    # 清除历史守护进程输出文件
    if [ -s "${WORK_DIR}/control.txt" ] || [ -s "${WORK_DIR}/dump.txt" ]; then
        rm -f "${WORK_DIR:?Error: WORK_DIR is not set}"/{control.txt,dump.txt} 2>/dev/null
    fi
    # 预检完成后认为环境没有问题, 输出启动成功提示
    printf "Current script version: %s Daemon process started. \xe2\x9c\x93 \n" "$VERSION" >> "$WORK_DIR/control.txt"
}

# independent logic called by a function
check_server() {
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"

    if ! pgrep -f "$SERVER_DIR/$APP_NAME" >/dev/null 2>&1; then
        cd "$SERVER_DIR" || return
        [ -f nohup.txt ] && mv -f nohup.txt "$LOG_DIR/nohup_${SERVER_NAME}_$(date -u '+%Y-%m-%d_%H:%M:%S' -d '+8 hours').txt"
        [ -f pid.txt ] && rm -f pid.txt >/dev/null 2>&1
        ./server.sh start &
        send_message "$SERVER_NAME Restart" &
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [ERROR] $SERVER_NAME Restart" >> "$WORK_DIR/dump.txt" &
    else
        echo "$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours') [INFO] $SERVER_NAME Running" >> "$WORK_DIR/control.txt" &
    fi
}

entry_check() {
    check_server "gate" "/data/server/gate"
    sleep 3s
    check_server "login" "/data/server/login"
    sleep 3s
}

global_check() {
    local BASE_PATH='/data/center'
    local GLOBAL_SERVER=()
    while IFS='' read -r row; do GLOBAL_SERVER+=("$row"); done < <(find "$BASE_PATH" -maxdepth 1 -type d -name "global*[0-9]" -printf "%f\n" | sed 's/global//' | sort -n)

    if [ "${#GLOBAL_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${GLOBAL_SERVER[@]}"; do
        SERVER_NAME="global$num"
        SERVER_DIR="$BASE_PATH/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

zk_check() {
    local BASE_PATH='/data/center'
    local ZK_SERVER=()
    while IFS='' read -r row; do ZK_SERVER+=("$row"); done < <(find "$BASE_PATH" -maxdepth 1 -type d -name "zk*[0-9]" -printf "%f\n" | sed 's/zk//' | sort -n)

    if [ "${#ZK_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${ZK_SERVER[@]}"; do
        SERVER_NAME="zk$num"
        SERVER_DIR="$BASE_PATH/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

game_check() {
    local GAME_SERVER=()
    while IFS='' read -r row; do GAME_SERVER+=("$row"); done < <(find /data -maxdepth 1 -type d -name "server*[0-9]" -printf "%f\n" | sed 's/server//' | sort -n)

    if [ "${#GAME_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${GAME_SERVER[@]}"; do
        SERVER_NAME="server$num"
        SERVER_DIR="/data/$SERVER_NAME/game"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

log_check() {
    local LOG_SERVER=()
    while IFS='' read -r row; do LOG_SERVER+=("$row"); done < <(find /data -maxdepth 1 -type d -name "logserver*[0-9]" -printf "%f\n" | sed 's/logserver//' | sort -n)

    if [ "${#LOG_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${LOG_SERVER[@]}"; do
        SERVER_NAME="logserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

api_check() {
    local API_SERVER=()
    while IFS='' read -r row; do API_SERVER+=("$row"); done < <(find /data -maxdepth 1 -type d -name "apiserver*[0-9]" -printf "%f\n" | sed 's/apiserver//' | sort -n)

    if [ "${#API_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${API_SERVER[@]}"; do
        SERVER_NAME="apiserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

cross_check() {
    local CROSS_SERVER=()
    while IFS='' read -r row; do CROSS_SERVER+=("$row"); done < <(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" -printf "%f\n" | sed 's/crossserver//' | sort -n)

    if [ "${#CROSS_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${CROSS_SERVER[@]}"; do
        SERVER_NAME="crossserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

gm_check() {
    local GM_SERVER=()
    while IFS='' read -r row; do GM_SERVER+=("$row"); done < <(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" -printf "%f\n" | sed 's/gmserver//' | sort -n)

    if [ "${#GM_SERVER[@]}" -eq 0 ]; then return; fi
    for num in "${GM_SERVER[@]}"; do
        SERVER_NAME="gmserver$num"
        SERVER_DIR="/data/$SERVER_NAME"
        check_server "$SERVER_NAME" "$SERVER_DIR"
        sleep 3s
    done
}

processcontrol() {
    pre_check

    while :; do
        entry_check
        global_check
        zk_check
        game_check
        log_check
        api_check
        cross_check
        gm_check
        sleep 3s
    done
}

processcontrol