#!/usr/bin/env bash
# 文件名: squid_traball_install.sh
# 功能: Squid 安装脚本

### 变量定义开始

export CPU_THREADS=${CPU_THREADS:-$(nproc)}                   # 编译线程数量
export SQUID_VERSION=${SQUID_VERSION:-3.5.23}                 # squid 版本
export SQUID_URL="http://www.squid-cache.org/Versions/v3/3.5/squid-${SQUID_VERSION}.tar.xz"
export OWNER=${OWNER:-squid}
export PREFIX=${1:-/usr/local/squid}                          # squid 安装目录

### 变量定义结束

set -eo pipefail

yum -y install gcc gcc-c++ automake imake autoconf bzip2-devel openssl-devel

id ${OWNER} >/dev/null 2>&1 || useradd ${OWNER} \
									--shell /sbin/nologin \
									--comment "Squid User" \
									--no-create-home

wget -c ${SQUID_URL}
tar axvf squid-${SQUID_VERSION}.tar.xz
cd squid-${SQUID_VERSION}
./configure \
	--enable-cachemgr-hostname=proxy.vqiu.cn \
    --prefix=${PREFIX} \
    --enable-dlmalloc \
	--enable-ssl-crtd \
	--enable-ssl \
	--with-openssl \
    --enable-removal-policies=heap,lru \
    --enable-default-err-language=Simplify_Chinese \
    --enable-cpu-profiling \
    --enable-err-languages="Simplify_Chinese English" \
    --enable-kill-parent-hack \
    --enable-snmp \
    --with-filedescriptors=65535 \
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
    --enable-arp-acl \
    --enable-icap-client \
	--enable-useragent-log \
	--enable-silent-rules \
	--with-default-user=squid &&
	make -j${CPU_THREADS} &&
	make install &&

chown -R ${OWNER}.${OWNER} ${PREFIX}
echo 'export PATH=$PATH:${PREFIX}/bin:${PREFIX}/sbin' > /etc/profile.d/squid.sh
source /etc/profile.d/squid.sh

cat >${PREFIX}/etc/squid.conf <<EOF
cache_mgr proxy@vqiu.cn
http_port  3128
#http_port 127.0.0.1:3128
#https_port 7788 cert=/etc/squid/g.vqiu.cn.pem key=/etc/squid/g.vqiu.cn.key

cache_dir ufs /data/squid 1000 16 256

coredump_dir /data/squid

# Visible Hostname
visible_hostname proxy.vqiu.com

# Cache size
cache_mem 384 MB

# Proxy DNS Server
dns_nameservers 223.5.5.5 223.6.6.6

# Error Display
error_directory ${PREFIX}/share/errors/zh-cn

## Auth
#auth_param basic program ${PREFIX}/libexec/basic_ncsa_auth ${PREFIX}/etc/.htpasswd
#auth_param basic children 5
#auth_param basic realm Squid Basic Authentication
#auth_param basic credentialsttl 5 hours
#acl password proxy_auth REQUIRED
#http_access allow password

http_access allow all

# not display IP address
forwarded_for off

# header
request_header_access Referer deny all
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all
EOF

cat >${PREFIX}/etc/.htpasswd <<EOF
shuhui:$apr1$Wt6fbVyi$AwfM3iR/bOuTxYZ7WQO8P1
EOF
