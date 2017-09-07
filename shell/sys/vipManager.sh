#!/bin/bash
# 文件名: vip_manager.sh
# 功能: 虚拟IP 管理脚本
# 树辉@2016

declare -A ip_pres=(
    [DenyUDP_subnet]="183.2.195"
    [Nolimit_subnet]="183.2.206"
)

if [[ $UID != 0 ]]; then
    echo "Please use root role to run this script."
    exit 1
fi

function vip_on() {

    for pre in ${ip_pres[*]}; do
        for host in {0..255}; do
            ip addr add ${pre}.${host}/32 dev lo
        done
    done
}

function vip_off() {

    for pre in ${ip_pres[*]}; do
        for host in {0..255}; do
            ip addr del ${pre}.${host}/32 dev lo
        done
    done
}

function user_define() {

    if [[ $# != 2 ]]; then
        echo "Please specify an address."
        exit 1
    fi

    ip addr $1 ${2}/32 dev lo >/dev/null 2>&1

    if [[ $? = 0 ]]; then
        echo "[+] IP: ${2}/32 handling success."
    else
        echo "[-] IP: ${2}/32 handling failed"
    fi
}

case $1 in
    up|on)
        vip_on
        ;;
    down|off)
        vip_off
        ;;
    -a)
        user_define add $2
        ;;
    -d)
        user_define del $2
        ;;
    *)
        echo "Usage: $0 [ up | on ] | [ down | off ] | -a address | -d address."
        exit 1
esac
