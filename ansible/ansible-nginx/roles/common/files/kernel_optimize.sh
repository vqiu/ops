#!/bin/bash
# Filename: kernel_optimize.sh
# Descript: kernel_optimize for web server

FILE=$(echo 'shuhui' | md5sum | cut -b1-25)

if [[ ! -e /tmp/${FILE} ]]
then 
	cat >> /etc/sysctl.conf <<EOF 

# Kernel Optimize
fs.file-max = 1048576
net.ipv4.tcp_max_syn_backlog = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.core.somaxconn = 65535
net.ipv4.tcp_rmem = 8192 87380 1048576
net.ipv4.tcp_wmem = 8192 87380 1048576
net.ipv4.tcp_mem = 786432   2097152 3145728
net.core.optmem_max = 81920

net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024  65535
# Disable SSR[Slow-Start Restart]
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_window_scaling = 0
net.ipv4.tcp_sack = 0

net.ipv4.conf.lo.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_source_route = 0

# Deny ICMP[1]
net.ipv4.icmp_echo_ignore_all = 0

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# TCP fast open
net.ipv4.tcp_fastopen = 1

# Swap space use ratio
vm.swappiness = 0

# Disable IPV6
net.ipv6.conf.all.disable_ipv6 = 1
EOF
	cat > /etc/security/limits.d/optimize.conf <<ENDF
	
*    soft    nofile    1048576
*    hard    nofile    1048576
ENDF

	touch /tmp/${FILE}
	source /etc/security/limits.conf
	/sbin/sysctl -p
fi
