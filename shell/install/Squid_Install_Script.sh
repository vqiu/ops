#!/usr/bin/env bash
#FileName: Squid_Install_Script.sh


# Make Threads 
cpu_threds=$(expr $(grep processor /proc/cpuinfo|wc -l) + 1)

# Private Network
LAN_NETWORK="192.168.198.0/24"

# Install Directory
PREFIX="/usr/local"
CACHE_DIR="/data/cache/squid"
LOG_DIR="/data/logs"


id squid 
if [ "$?" -ne "0" ]
then
	useradd squid -s /sbin/nologin -c "Squid User"
fi

function SYS_INIT() {
	cat >> /etc/security/limits.conf <<ENDF
	
*    soft    nofile    51200
*    hard    nofile    51200
ENDF

cat >> /etc/sysctl.conf <<ENDF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024  40000
# Disable SSR
net.ipv4.tcp_slow_start_after_idle=0
fs.file-max=51200
# Set keepalive
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 20
net.ipv4.tcp_keepalive_probes = 3
ENDF
	sysctl -p
}


function INSTALL() {
	for pkg in gcc gcc-c++ automake autoconf bzip2-devel
	do
		yum -y install ${pkg}
	done

	wget http://www.squid-cache.org/Versions/v3/3.5/squid-3.5.5.tar.bz2
	tar xjvf squid-3.5.5.tar.bz2
	cd squid-3.5.5
	./configure \
	--prefix=${PREFIX}/squid \
	--enable-dlmalloc \
	--enable-removal-policies=heap,lru \
	--enable-default-err-language=Simplify_Chinese \
	--enable-cpu-profiling \
	--enable-err-languages="Simplify_Chinese English" \
	--enable-kill-parent-hack \
	--enable-snmp \
	--enable-stacktrace \
	--disable-ident-lookups \
	--with-large-files \
	--enable-linux-netfilter \
	--enable-linux-tproxy \
	--enable-epoll \
	--enable-delay-pools \
	--enable-icmp \
	--enable-htcp \
	--enable-cache-digests \
	--disable-wccp \
	--with-filedescriptors=65536 \
	--enable-arp-acl \
	--with-default-user=squid
	make -j${cpu_threds}
	make install
	
	chown -R squid.squid ${PREFIX}/squid 
	echo 'export PATH=$PATH:${PREFIX}/squid/bin:${PREFIX}/squid/sbin' > /etc/profile.d/squid.sh
	source /etc/profile.d/squid.sh
	
	mv ${PREFIX}/squid/etc/squid.conf ${PREFIX}/squid/etc/squid.conf.save
}


function CONFIGURE() {

	cat > ${PREFIX}/squid/etc/squid.conf <<EOF
visible_hostname cache.dd.com
#http_port 3128 transparent
http_port 3128
http_port 3129 intercept
dns_nameservers 223.5.5.5 223.6.6.6

cache_mgr report@vqiu.cn
cache_effective_user squid
cache_effective_group squid

# Cache Memory Size
cache_mem 1024 MB

# Cache Directory
coredump_dir ${CACHE_DIR}

# Cache Store Size
cache_dir ufs ${CACHE_DIR} 100000 32 256
cache_swap_low 90
cache_swap_high 95
maximum_object_size 4 MB
minimum_object_size 1 bytes
maximum_object_size_in_memory 4 MB
memory_replacement_policy lru
cache_replacement_policy lru

memory_pools on
memory_pools_limit 64 MB

pid_filename ${PREFIX}/squid/var/logs/squid.pid
access_log ${LOG_DIR}/access.log
cache_store_log none
#cache_store_log ${LOG_DIR}/store.log
cache_log ${LOG_DIR}/cache.log
forwarded_for off 

# Error Display
error_directory ${PREFIX}/squid/share/errors/zh-cn

redirect_children 30
fqdncache_size 51200
ipcache_size 51200
ipcache_low 90
ipcache_high 95

# No Cache Content
acl QUERY urlpath_regex cgi-bin \? .php .cgi .asp .aspx .jsp .do .avi .wmv .zip .exe
cache deny QUERY


acl daidaicn url_regex -i ^http://*?.daidaicn.com/.*?.*$
acl daidaicn url_regex -i ^http://114.215.173.147/.*?.*$
acl daidaicn url_regex -i ^http://*?.168jr.com/.*?.*$
acl daidaicn url_regex -i ^http://*?.qiandour.com/.*?.*$

no_cache deny daidaicn

# Hidden Squid Version
reply_header_access Via deny all
reply_header_access Cache-Control deny all
reply_header_access Server deny all
reply_header_access X-Squid-Error deny all
reply_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Age deny all
request_header_access X-Squid-Error deny all
request_header_access Pragma deny all


# ACL
acl localnet src ${LAN_NETWORK}  # RFC1918 possible internal network

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

http_access deny !Safe_ports

http_access deny CONNECT !SSL_ports

http_access allow localhost manager
http_access deny manager

#http_access deny to_localhost

http_access allow localnet
http_access allow localhost

http_access deny all

# squidGuard setting
#url_rewrite_program /usr/local/bin/squidGuard -c ${PREFIX}/squidGuard/squidGuard.conf

EOF

}

function SquidGuard() {
	
	yum -y install db4 db4-devel
	
	wget http://www.squidguard.org/Downloads/squidGuard-1.4.tar.gz
	tar zxvf squidGuard-1.4.tar.gz;cd squidGuard-1.4	
	./configure
	make -j${cpu_threds}
	make install
	
	sed -i "s/#url_rewrite_program \/usr\/local\/bin/squidGuard -c ${PREFIX}\/squidGuard\/squidGuard.conf/url_rewrite_program \/usr\/local\/bin\/squidGuard -c ${PREFIX}\/squidGuard\/squidGuard.conf/g" ${PREFIX}/squid/etc/squid.conf
	mkdir -pv ${PREFIX}/squidGuard/db/blacklist;cd ${PREFIX}/squidGuard/db/blacklist
	
	wget -c https://down.vqiu.cn/package/tarball/squid/squidGuard/domains
	wget -c https://down.vqiu.cn/package/tarball/squid/squidGuard/urls
	
	squidGuard -b -C domains
	squidGuard -b -C urls
	
	mv ${PREFIX}/squidGuard/squidGuard.conf ${PREFIX}/squidGuard/squidGuard.conf.default
	
	wget -c https://down.vqiu.cn/package/tarball/squid/squidGuard/squidGuard.conf
	
	chown squid.squid /usr/local/squidGuard -R	
	squid -k reconfigure

}


SYS_INIT
INSTALL
CONFIGURE
SquidGuard





