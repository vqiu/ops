#!/bin/bash
# Author: shuhui@2015

# 定义版本号
VER='1.2.19'

# 定义下载路径
URL="http://down.vqiu.cn/package/tarball/keepalived/keepalived-${VER}.tar.gz"


function Install {
	cd /usr/local/src
	wget -c ${URL}
	tar zxvf keepalived-${VER}.tar.gz;cd keepalived-${VER}
	./configure \
		--prefix=/usr/local/keepalived \
		--sysconfdir=/etc
	make;make install

	# 创建软链接
	if [[ ! -e /usr/sbin/keepalived ]]; then
		ln -s /usr/local/keepalived/sbin/keepalived /usr/sbin/
	fi

	if [[ ! -e /usr/bin/genhash ]]; then
		ln -s /usr/local/keepalived/bin/genhash /usr/bin/
	fi
}

Install
