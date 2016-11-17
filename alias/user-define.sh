# /etc/profile.d/user-define.sh

# curl 命令增加版
alias curld='curl -s -o /dev/null -w \
"
              请求时间:  '$(date +%y-%m-%dT%T+08:00)'
            HTTP状态码:  %{http_code}
           DNS解析时间:  %{time_namelookup} s
          建立连接时间:  %{time_connect} s
          连接完成时间:  %{time_appconnect} s
          准备传输时间:  %{time_pretransfer} s
            重定向时间:  %{time_redirect} s
          传输开始时间:  %{time_starttransfer} s
        请求数据包大小:  %{size_request} Bytes
        下载数据包大小:  %{size_download} Bytes
          平均下载速度:  %{speed_download} Bytes/s
                         --------------
            消耗总时长:  %{time_total} s \n
"'

# curl 命令简洁版
alias curlb='curl -s -o /dev/null -w \
"'$(date +%y-%m-%dT%T+08:00)' %{http_code} %{time_namelookup} %{time_connect} %{time_appconnect} %{time_pretransfer} %{time_redirect} %{time_starttransfer} %{size_request} %{size_download} %{speed_download} %{time_total}\n"'

# 网络连接最大数
alias conn_max="netstat -na|awk '\$5 ~ /[0-9]+:[0-9]+/ {print \$5}' |awk -F ':' -- '{print \$1}' |sort -n|uniq -c |sort -rn|tail -n 15"

# TCP连接状态数据
alias conn_ts="netstat -n | awk '/^tcp/ {++S[\$NF]} END {for(a in S) print a, S[a]}'"

mcd() { mkdir -p "\$1"; cd "\$1";}
alias ..="cd .."
alias ...="cd ../../"
alias listen="lsof -P -i -n"
alias ll="ls -al --color=auto"
alias randPass="openssl rand -base64 32"
