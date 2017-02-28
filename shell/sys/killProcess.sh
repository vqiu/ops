#!/bin/bash
# 文件名: killProcess.sh
# 描述: 快速结束进程脚本
# 作者: shuhui

# 匹配一个进程的PID: kill `ps -ef | grep -w processName | grep -v grep | awk '{print $2}'`
# pgrep 无法精确匹配一个完整的进程名称[防止进程被误杀]，故以 pidof 命令来替代

for process in "$@"
do
        for pids in `pidof ${process}`
        do
                for pid in ${pids}
                do
                        kill -9 ${pid} && \
                        echo "Process: ${process}[${pid}] has been killed"
                done
        done
done
