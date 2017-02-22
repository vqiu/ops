#!/bin/bash
# 文件名: php7-fpm.sh
# 作者: shuhui
# 版本: v1.5

### 更新日志 ###
# 2015-11-28 版本 v1.0: 1、以 7.0 为版本为基础，实现常用的 PHP-CGI 功能
# 2016-01-04 版本 v1.1: 1、更新 PHP版本为7.0.1  2、增加编译并行数量  3、添加 opcache 模块至 php.ini 文件 4、去除函数运行方式
# 2016-04-11 版本 v1.2: 1、更新 PHP版本为7.0.5  2、简化 $CPU_NUM 变量
# 2016-05-03 版本 v1.3: 1、更新 PHP版本为7.0.6  2、新增编译选项  --with-gettext --enable-exif 及 --with-mysql
# 2016-05-27 版本 v1.4: 1、更新 PHP版本为7.0.7
# 2016-01-11 版本 v1.5: 1、更新 PHP版本为7.1 2. 简化安装过程

### 变量定义区域 开始 ###

PREFIX=/usr/local                                  # 安装路径
PHP_VER=7.0.7                                      # PHP 版本号
CPU_NUM=$(nproc)                                   # CPU 核心数量[编译并行数量]
OPCACHE_MEM_SIZE=128                               # Opcache 内存分配大小

### 变量定义区域 结束 ###

[[ -e php-${PHP_VER}.tar.bz2 ]] || wget -c http://mirrors.sohu.com/php/php-${PHP_VER}.tar.bz2
tar axvf php-${PHP_VER}.tar.bz2
cd php-${PHP_VER}
make clean
./configure \
--prefix=${PREFIX}/php-${PHP_VER} \
--with-config-file-path=${PREFIX}/php-${PHP_VER}/etc \
--with-mysql \
--with-mysqli \
--with-pdo-mysql \
--enable-fpm \
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
--with-mcrypt=${PREFIX}/libmcrypt \
--with-gd=${PREFIX}/gd2 \
--with-freetype-dir=${PREFIX}/freetype \
--with-jpeg-dir=${PREFIX}/jpeg \
--with-png-dir=${PREFIX}/libpng \
--disable-ipv6 \
--disable-debug \
--with-openssl \
--disable-maintainer-zts \
--enable-opcache \
--with-gettext \
--enable-exif \
--disable-fileinfo &&
make -j${CPU_NUM} &&
make install

if [[ $? -eq 0 ]]; then
    # 建立软链接
    ln -sv ${PREFIX}/php-${PHP_VER} ${PREFIX}/php
    
    # 建立配置文件
    \cp php.ini-production ${PREFIX}/php/etc/php.ini		
    
    \cp ${PREFIX}/php/etc/php-fpm.conf.default ${PREFIX}/php/etc/php-fpm.conf
    \cp ${PREFIX}/php/etc/php-fpm.d/www.conf.default ${PREFIX}/php/etc/php-fpm.d/www.conf
    
    \cp sapi/fpm/php-fpm.service /usr/lib/systemd/system/
    sed -i "s:\${prefix}:${PREFIX}/php:" /usr/lib/systemd/system/php-fpm.service
    sed -i "s:\${exec_prefix}:${PREFIX}/php:" /usr/lib/systemd/system/php-fpm.service

     # 修改 php.ini 参数
     for i in ${PREFIX}/php/etc/php.ini
     do
         sed -i 's#output_buffering = Off#output_buffering = On#' $i
         sed -i 's/post_max_size = 8M/post_max_size = 20M/g' $i
         sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' $i
         sed -i 's/;date.timezone =/date.timezone = PRC/g' $i
         sed -i 's/short_open_tag = Off/short_open_tag = On/g' $i
         sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $i
         sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' $i
         sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $i
         sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' $i
     done
     
     # 添加 opcached 模块至 php.ini
     echo -en "\n\n[opcache]\nzend_extension=opcache.so\nopcache.enable=1\nopcache.memory_consumption=${OPCACHE_MEM_SIZE}\nopcache.interned_strings_buffer=8\nopcache.revalidate_freq=300\nopcache.max_accelerated_files=5000\nopcache.fast_shutdown=1\nopcache.save_comments=0\n" >> ${PREFIX}/php/etc/php.ini
     # 添加到系统环境变量
     echo "export PATH=\$PATH:${PREFIX}/php/bin">/etc/profile.d/php.sh
     source /etc/profile.d/php.sh
     
    systemctl daemon-reload
    systemctl start php-fpm.service
    systemctl enable php-fpm.service
fi
