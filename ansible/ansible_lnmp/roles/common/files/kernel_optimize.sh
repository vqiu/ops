#!/bin/bash
# Filename: kernel_optimize
# Descript: kernel_optimize for web server

FILE='/tmp/kernel_optimized_shuhui'

if [[ ! -e ${FILE} ]]
then 
	cat >> /etc/sysctl.conf <<EOF 

# Kernel Optimize
fs.file-max=65535
net.ipv4.tcp_max_syn_backlog = 262144
net.core.netdev_max_backlog =  262144
net.core.somaxconn = 32768
net.ipv4.tcp_max_orphans = 262144
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024  65000
# Disable SSR
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_window_scaling = 0
net.ipv4.tcp_sack = 0
EOF
	cat >> /etc/security/limits.conf <<ENDF
	
*    soft    nofile    65535
*    hard    nofile    65535
ENDF
	touch ${FILE}
	source /etc/security/limits.conf
	/sbin/sysctl -p
fi
