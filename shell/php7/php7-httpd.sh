#!/bin/bash
# 文件名: php7-httpd.sh
# 作者: shuhui
# 版本: v1.2

### 更新日志 ###
# 2015-11-28 版本 v1.0: 1、以 7.0 为版本为基础，实现常用的 PHP 功能
# 2016-01-04 版本 v1.1: 1、更新 PHP版本为7.0.1  2、增加编译并行数量
# 2016-01-05 版本 v1.2: 1、为 apxs 添加单独变量  2、增加 apxs 文件存在判断

### 变量定义区域 开始 ###

PREFIX=/usr/local                                  # 安装路径
PHP_VER=7.0.1                                      # PHP 版本号
CPU_NUM=$(grep -c processor /proc/cpuinfo)         # CPU 核心数量[编译并行数量]
APXS2=/usr/local/apache24/bin/apxs                 # Apache apxs 程序路径[务必存在]

### 变量定义区域 结束 ###

# 判断 apxs 文件是否存在
function apxs_exist() {
    if [ ! -f ${APXS2} ]; then
        echo 'apxs not exists'
        exit 1
    fi
}

# 安装php-7
function php7_install() {
	[[ -e php-${PHP_VER}.tar.bz2 ]] || wget -c https://down.vqiu.cn/package/tarball/php/php-${PHP_VER}.tar.bz2
	tar axvf php-${PHP_VER}.tar.bz2
	cd php-${PHP_VER}
	./configure \
	--prefix=${PREFIX}/php7 \
	--with-apxs2=${APXS2} \
	--with-config-file-path=${PREFIX}/php7/etc \
	--enable-mysqlnd \
	--enable-static \
	--enable-inline-optimization \
	--enable-sockets \
	--enable-wddx \
	--enable-zip \
	--enable-calendar \
	--enable-bcmath \
	--enable-soap \
	--with-zlib \
	--with-iconv \
	--with-xmlrpc \
	--enable-mbstring \
	--without-sqlite3 \
	--without-pdo-sqlite \
	--with-curl \
	--enable-ftp \
	--with-mcrypt=${PREFIX}/libmcrypt/ \
	--with-gd=${PREFIX}/gd2/ \
	--with-freetype-dir=${PREFIX}/freetype/ \
	--with-jpeg-dir=${PREFIX}/jpeg/ \
	--with-png-dir=${PREFIX}/libpng/ \
	--disable-ipv6 \
	--disable-debug \
	--with-openssl \
	--enable-opcache \
	--disable-fileinfo
	[[ ${CPU_NUM} -gt 1 ]] && make -j${CPU_NUM} || make
	make install

    if [[ $? -eq 0 ]]; then
    
    	# 建立软链接
        ln -sv ${PREFIX}/php7 ${PREFIX}/php
        
        # 建立配置文件
        \cp php.ini-production ${PREFIX}/php/etc/php.ini
		       
        # 修改 php.ini 参数
        for i in ${PREFIX}/php/etc/php.ini
        do
            sed -i 's#output_buffering = Off#output_buffering = On#' $i
            sed -i 's/post_max_size = 8M/post_max_size = 20M/g' $i
            sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' $i
            sed -i 's/;date.timezone =/date.timezone = PRC/g' $i
            sed -i 's/short_open_tag = Off/short_open_tag = On/g' $i
            sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $i
            sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' $i
        done
        
        # 添加到系统环境变量
        echo "export PATH=\$PATH:${PREFIX}/php/bin">/etc/profile.d/php.sh
        source /etc/profile.d/php.sh
    fi
}

apxs_exist
php7_install
