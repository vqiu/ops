#!/bin/bash
# 文件名: sshProxy.sh

HOST=xx.xx.xx.xx
PORT=22
DSTPORT=62223
SRCPORT=22

API=http://myip.ipip.net
IP_FILE=/tmp/lastIP.txt

touch ${IP_FILE}
function sshConn() {
        ssh -CnfNT -R *:${DSTPORT}:127.0.0.1:${SRCPORT} ${HOST} -p ${PORT}

        ### SSH参数解释
        # -C 压缩数据传输
        # -f 认证之后，扔到后台运行
        # -n 将 stdio 重定向到 /dev/null，与 -f 配合使用
        # -N 不执行脚本或命令，不运行设定的 shell 通常与 -f 连用
        # -T 不分配 TTY，仅代理
        # -q 安静模式
}

MYIP=`curl -sB ${API} | awk '{print $2}' | cut -b 6- | grep -o -P "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
if [[ ! -z ${MYIP} ]]
then
        PID=`ps -ef | grep -v 'grep'|grep "ssh.*${DSTPORT}.*.${HOST}" | awk '{print $2}'`
        if [[ -z ${PID} ]]
        then
                sshConn
        else
                if [[ "${MYIP}" != "$(cat ${IP_FILE})" ]]
                then
                        kill -9 ${PID}
                        sleep 3
                        sshConn
                        echo ${MYIP}>${IP_FILE}
                else
                        logger -t "`basename $0 .sh`" "ip dose not changed."
                        exit 0
                fi
        fi
else
        logger -t "`basename $0 .sh`" "does not fetch publicIP."
        exit 1
fi
