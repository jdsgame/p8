#!/usr/bin/env bash
#
# Description: distributes ssh keys across multiple hosts.
#
# Copyright (c) 2025 zzwsec <zzwsec@163.com>
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: MIT

set \
    -o errexit \
    -o nounset

readonly version='v0.0.3 (2025.03.19)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mError${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1mSuccess${white} $*"; }

os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')

# 定义被控服务器
declare -a control_hosts
control_hosts=()
# sshkey秘钥存储路径
sshkey_path="$HOME/.ssh/id_rsa"
# 主机秘钥
host_password=''

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
        elif _exists zypper; then
            zypper install -y "$package"
        fi
    done
}

pre_check() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    _yellow "当前脚本版本: $version \xF0\x9F\x8D\xB4 "
    # 操作系统和权限校验
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red '此脚本必须以root身份运行!')" && exit 1
    fi
    if [ "$os_name" != "alinux" ] && [ "$os_name" != "almalinux" ] \
        && [ "$os_name" != "centos" ] && [ "$os_name" != "debian" ] \
        && [ "$os_name" != "fedora" ] && [ "$os_name" != "opencloudos" ] \
        && [ "$os_name" != "opensuse" ] && [ "$os_name" != "rhel" ] \
        && [ "$os_name" != "rocky" ] && [ "$os_name" != "ubuntu" ]; then
        _err_msg "$(_red '当前操作系统不受支持!')" && exit 1
    fi
}

sshkey_check() {
    if [ ! -f "$sshkey_path" ]; then
        if ! ssh-keygen -t rsa -f "$sshkey_path" -P '' >/dev/null 2>&1; then
            _err_msg "$(_red '密钥创建失败, 请重试!')" && exit 1
        fi
    fi
}

sshkey_send() {
    if [ "${#control_hosts[@]}" -eq 0 ]; then _err_msg "$(_red '主机清单为空')" && exit 1; fi
    if [ -z "$host_password" ]; then _err_msg "$(_red '主机密码为空, 请检查脚本配置!')" && exit 1; fi

    if ! _exists sshpass >/dev/null 2>&1; then
        pkg_install sshpass
    fi
    # 并行执行提高效率
    for host in "${control_hosts[@]}"; do
        # 启动子进程, 每个分发操作完全独立运行在新的进程中
        # 子进程报错退出避免主机过多导致进程崩溃
        (
            _yellow "正在向 $host 分发公钥."
            if ! sshpass -p"$host_password" ssh-copy-id -i "$sshkey_path" -o StrictHostKeyChecking=no -o ConnectTimeout=30 root@"$host" >/dev/null 2>&1; then
                _err_msg "$(_red "$host 公钥分发失败!")" && exit 1
            fi
            _suc_msg "$(_green "$host 公钥分发成功")"
        ) &
    done
    # 等待并行任务
    wait
}

ssh_divide() {
    pre_check
    sshkey_check
    sshkey_send
}

ssh_divide