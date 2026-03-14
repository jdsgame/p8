#!/bin/bash
# shellcheck disable=all
# time: 2025/3/11

set -o nounset

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
white='\033[0m'

_err_msg() { echo -e "\033[41m\033[1m警告${white} $1"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $1"; }
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $1"; }

process_book=playbook/process/process-entry.yaml
login_book=playbook/login/login-entry.yaml
gate_book=playbook/gate/gate-entry.yaml
game_book=playbook/game/game-entry.yaml
cross_book=playbook/cross/cross-entry.yaml
gm_book=playbook/gm/gm-entry.yaml
global_book=playbook/global/global-entry.yaml
log_book=playbook/log/log-entry.yaml
zk_book=playbook/zk/zk-entry.yaml

err_exit() {
    _err_msg "$1"
    exit "$2"
}

_show_spinner() {
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local msg="$1"
    local pid="$2"
    local i=0
    local len=${#spinstr}
    while kill -0 "$pid" 2> /dev/null; do
        printf "\r  ${yellow}%s [%s]${white}" "$msg" "${spinstr:i++%len:1}"
        sleep 0.1
    done
    printf "\r\033[K"
}

print_info_and_execute_playbook() {
    local option="$1"
    if [ "$option" == "stop" ]; then
        _info_msg "执行 stop 操作, 按任意键继续..."
        read -r
        update_stop
    elif [ "$option" == "start" ]; then
        _info_msg "执行 start 操作, 按任意键继续..."
        read -r
        update_start
    else
        err_exit "异常值" 3
    fi
}

update_start() {
    update_option "$zk_book" "start"
    update_option "$log_book" "start"
    update_option "$global_book" "start"
    update_option "$cross_book" "start"
    update_option "$gm_book" "start"
    update_option "$game_book" "start"
    update_option "$gate_book" "start"
    update_option "$login_book" "start"
    update_option "$process_book" "start"
}

update_stop() {
    update_option "$process_book" "stop"
    update_option "$login_book" "stop"
    update_option "$gate_book" "stop"
    update_option "$game_book" "stop"
    update_option "$cross_book" "stop"
    update_option "$gm_book" "stop"
    update_option "$global_book" "stop"
    update_option "$log_book" "stop"
    update_option "$zk_book" "stop"
}

update_option() {
    local playbook_path="$1"
    local flag="$2"

    [[ ! -f "$playbook_path" ]] && err_exit "playbook 文件 $playbook_path 不存在" 1
    local node_name=$(awk -F '/' '{print $2}' <<< "$playbook_path")
    local log_file="./runlog/${flag}_${node_name}.log"
    printf "当前时间: %s\n" "$(date +%F\ %T)" >> "$log_file"
    ansible-playbook "$playbook_path" -t "$flag" >> "$log_file" 2>&1 &
    local task_pid=$!

    if ! kill -0 "$task_pid" 2> /dev/null; then
        err_exit "无法启动 Ansible" 1
    fi

    _show_spinner "正在：${flag}-->${node_name} node" "$task_pid" &
    local spinner_pid=$!
    wait "$task_pid"
    local task_status=$?

    # 停止并清理动画
    kill "$spinner_pid" 2> /dev/null
    wait "$spinner_pid" 2> /dev/null || true
    printf "\r\033[K" # 清理动画行

    if [ "$task_status" -ne 0 ]; then
        printf "  ${red}${flag}-->%s node [失败], 执行过程见 %s${white}\n" "$node_name" "$log_file"
        exit 1
    else
        printf "  ${green}${flag}-->%s node [完成]${white}\n" "$node_name"
    fi
}

[[ ! -d ./playbook/ ]] && err_exit "错误：目录 ./playbook/ 不存在" 1
[[ ! -f ./hosts ]] && err_exit "错误：文件 ./hosts 不存在" 1
command -v ansible &> /dev/null || err_exit "错误：ansible 未安装" 1
[[ ! -d ./runlog/ ]] && mkdir -p ./runlog

if [ $# -eq 0 ]; then
    err_exit "参数数量错误" 2
fi

case $1 in
start)
    print_info_and_execute_playbook "start"
    ;;
stop)
    print_info_and_execute_playbook "stop"
    ;;
*)
    err_exit "参数类型错误" 2
    ;;
esac
