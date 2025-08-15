#!/usr/bin/env bash
#
# Description: Automatically determines the server path and reloads configurations.
#
# Copyright (c) 2024-2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

# https://github.com/koalaman/shellcheck/wiki/SC2207
# shellcheck disable=SC2207

set \
    -o nounset

readonly version='v0.2.2 (2025.03.05)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
cyan='\033[96m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mError${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1mSuccess${white} $*"; }
_info_msg() { echo -e "\033[46m\033[1mTip${white} $*"; }

# 分隔符
separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

# 预定义常量
# https://github.com/koalaman/shellcheck/wiki/SC2155
readonly reload_pid='/tmp/reload.pid'
readonly local_update_dir='/data/update'
readonly remote_update_file='/data/update/updategame.tar.gz'
readonly control_host='10.46.99.186'
readonly control_host_passwd=''

os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

if [ -f "$reload_pid" ] && kill -0 "$(cat "$reload_pid")" 2>/dev/null; then
    _err_msg "$(_red 'The script is running, please do not repeat the operation!')" && exit 1
fi

# 将当前进程写入pid防止并发执行导致冲突
echo $$ > "$reload_pid"

_exit() {
    [ -f "$reload_pid" ] && rm -f "$reload_pid"
}

_exists() {
    local _cmd="$1"
    if type "$_cmd" >/dev/null 2>&1; then
        return 0
    elif command -v "$_cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

pkg_install() {
    for package in "$@"; do
        _yellow "Installing $package"
        if _exists dnf; then
            dnf install -y "$package"
        elif _exists yum; then
            yum install -y "$package"
        elif _exists apt; then
            DEBIAN_FRONTEND=noninteractive apt install -y -q "$package"
        elif _exists apt-get; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$package"
        elif _exists apk; then
            apk add --no-cache "$package"
        elif _exists pacman; then
            pacman -S --noconfirm --needed "$package"
        elif _exists zypper; then
            zypper install -y "$package"
        fi
    done
}

# 清屏函数
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

# 二次重读, 确保所有lua脚本生效
stress_cmd() {
    local _cmd="$1"
    local _delay="${2:-1}" # 默认等待1秒
    for (( i=1; i<=2; i++ )); do
        ./server.sh "$_cmd"
        [ "$i" -lt 2 ] && sleep "$_delay"
    done
}

# 运行校验
pre_check() {
    local install_depend_pkg
    install_depend_pkg=( "sshpass" "tar" )

    clear_screen
    echo "$(_cyan 'Current script version') $(_yellow "$version")"
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script requires Bash as the shell interpreter!')" && exit 1
    fi
    if [ "$os_name" != "alinux" ] && [ "$os_name" != "almalinux" ] \
        && [ "$os_name" != "centos" ] && [ "$os_name" != "debian" ] \
        && [ "$os_name" != "fedora" ] && [ "$os_name" != "opencloudos" ] \
        && [ "$os_name" != "opensuse" ] && [ "$os_name" != "rhel" ] \
        && [ "$os_name" != "rocky" ] && [ "$os_name" != "ubuntu" ]; then
        _err_msg "$(_red 'The current operating system is not supported!')" && exit 1
    fi
    if [ -z "$control_host_passwd" ]; then
        _err_msg "$(_red 'The host password is empty, please check script config!')" && exit 1
    fi
    for pkg in "${install_depend_pkg[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            pkg_install "$pkg"
        fi
    done
}

# 获取更新包
get_updatefile() {
    if ! cd "$local_update_dir" 2>/dev/null; then
        mkdir -p "$local_update_dir" && cd "$local_update_dir" || exit 1
    fi

    rm -rf ./*

    if ! sshpass -p "$control_host_passwd" scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@$control_host:$remote_update_file" "$local_update_dir/"; then
        _err_msg "$(_red 'Download failed, please check network connection.')" && exit 1
    fi
    if [ ! -e "$local_update_dir/updategame.tar.gz" ]; then
        _err_msg "$(_red 'The update package was not downloaded correctly, please check.')" && exit 1
    fi
    if tar xvf "$local_update_dir/updategame.tar.gz"; then
        _suc_msg "$(_green "Successfully decompressed! \xe2\x9c\x93")"
    else
        _err_msg "$(_red "Decompression failed. \xe2\x9c\x97")" && exit 1 
    fi
    printf "\n"
}

# 游戏服
execute_gameserver() {
    local game_server
    game_server=($(find /data -maxdepth 1 -type d -name "server*[0-9]" | sed 's:.*/server::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#game_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GameServer list is empty.')" && return; fi
    get_updatefile
    for num in "${game_server[@]}"; do
        Spell_Dir="/data/server$num/game"
        _yellow "Processing GameServer$num ."
        \cp -rf "$local_update_dir/app/"* "$Spell_Dir/"
        cd "$Spell_Dir" || continue
        stress_cmd reload && _suc_msg "$(_green "GameServer$num update success! \xe2\x9c\x93")"
        separator
    done
}

# 日志服
execute_logserver() {
    local log_server
    log_server=($(find /data -maxdepth 1 -type d -name "logserver*[0-9]" | sed 's:.*/logserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#log_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The LogServer list is empty.')" && return; fi
    get_updatefile
    for num in "${log_server[@]}"; do
        Spell_Dir="/data/logserver$num"
        _yellow "Processing LogServer$num ."
        \cp -rf "$local_update_dir/app/"* "$Spell_Dir/"
        cd "$Spell_Dir" || continue
        stress_cmd reload && _suc_msg "$(_green "LogServer$num update success! \xe2\x9c\x93")"
        separator
    done
}

# 跨服
execute_crossserver() {
    local cross_server
    cross_server=($(find /data -maxdepth 1 -type d -name "crossserver*[0-9]" | sed 's:.*/crossserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#cross_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The CrossServer list is empty.')" && return; fi
    get_updatefile
    for num in "${cross_server[@]}"; do
        Spell_Dir="/data/crossserver$num"
        _yellow "Processing CrossServer$num ."
        \cp -rf "$local_update_dir/app/"* "$Spell_Dir/"
        cd "$Spell_Dir" || continue
        stress_cmd reload && _suc_msg "$(_green "CrossServer$num update success! \xe2\x9c\x93")"
        separator
    done
}

# GM
execute_gmserver() {
    local gm_server
    gm_server=($(find /data -maxdepth 1 -type d -name "gmserver*[0-9]" | sed 's:.*/gmserver::' | sort -n | awk '{if(NR>1)printf " ";printf "%s", $0}'))

    if [ "${#gm_server[@]}" -eq 0 ]; then _info_msg "$(_cyan 'The GMServer list is empty.')" && return; fi
    get_updatefile
    for num in "${gm_server[@]}"; do
        Spell_Dir="/data/gmserver$num"
        _yellow "Processing GMServer$num ."
        \cp -rf "$local_update_dir/app/"* "$Spell_Dir/"
        cd "$Spell_Dir" || continue
        stress_cmd reload && _suc_msg "$(_green "GMServer$num update success! \xe2\x9c\x93")"
        separator
    done
}

reload() {
    pre_check
    execute_gameserver
    execute_logserver
    execute_crossserver
    execute_gmserver
}

reload