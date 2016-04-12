#!/bin/bash
# 文件名: php_depend.sh
# 作者: shuhui
# 版本: v1.1

### 更新日志 ###
# 2015-11-28 版本 v1.0: 1.实现简单的 PHP 编译依赖包
# 2016-01-04 版本 v1.1: 1.锁定 $OWNER 变量的 GID UID 2.下载 Tarball 包使用简单逻辑判断

### 变量定义区域 开始 ###

OWNER=www                                          # 运行用户
PREFIX=/usr/local                                  # 安装根路径
uid=2000                                           # OWNER 用户 UID
gid=2000                                           # OWNER 用户 GID
DOCUMENT_ROOT=/data/www                            # 网站存放目录
CPU_NUM=$(grep -c "processor" /proc/cpuinfo)       # 编译并行数量

LIBICONV_VER=1.14                                  # iconv 版本
ZLIB_VER=1.2.8                                     # zlib 版本
FREETYPE_VER=2.1.10                                # freetype 版本
LIBPNG_VER=1.5.23                                  # libpng 版本
JPEG_VER=9a                                        # jpeg 版本
LIBMCRYPT_VER=2.5.8                                # libmcrypt 版本
LIBEVENT_VER=2.0.22                                # libevent 版本
GD2_VER=2.1.1                                      # gd2 版本

### 变量定义区域 结束 ###

# 判断当前用户是否为 root,否则退出
if [ ${UID} != "0" ]; then
	echo "Error: Please use root role to install me!"
	exit 67;

fi

# 创建 运行用户
function user_create() {
	id ${OWNER} >/dev/null 2>&1
	if [[ $? -eq "1" ]];
	then
		/usr/sbin/groupadd ${OWNER} -g ${gid}
	    /usr/sbin/useradd -g ${gid} -u ${uid} ${OWNER} -s /sbin/nologin -d ${DOCUMENT_ROOT};
	fi
}

# 安装依赖包
function yum_depend() {
	for pkg in gcc gcc-c++ libXpm-devel openssl-devel curl-devel libxml2-devel glibc-devel glib2-devel bzip2 bzip2-devel ncurses-devel curl-devel e2fsprogs-devel krb5-devel libidn-devel libjpeg-devel libpng-devel wget
	do
		yum -y install $pkg
	done
}

# 安装 libiconv
function libiconv_install() {
	[[ -f libiconv-${LIBICONV_VER}.tar.gz ]] || https://down.vqiu.cn/package/tarball/php_depend/libiconv-${LIBICONV_VER}.tar.gz
	rm -rf libiconv-${LIBICONV_VER}
	tar axvf libiconv-${LIBICONV_VER}.tar.gz
	cd libiconv-${LIBICONV_VER}
	./configure --prefix=/usr/local
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install
	cd ..
}

# 安装 zlib
function zlib_install() {
	[[ -f zlib-${ZLIB_VER}.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/zlib-${ZLIB_VER}.tar.gz

	rm -rf zlib-${ZLIB_VER}
	tar axvf zlib-${ZLIB_VER}.tar.gz
	cd zlib-${ZLIB_VER}
	./configure
	if [ $CPU_NUM -gt 1 ];then
		make CFLAGS=-fpic -j$CPU_NUM
	else
		make CFLAGS=-fpic
	fi
	make install
	cd ..
}

# 安装 freetype
function freetype_install() {
	[[ -f freetype-${FREETYPE_VER}.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/freetype-${FREETYPE_VER}.tar.gz
	rm -rf freetype-${FREETYPE_VER}
	tar axvf freetype-${FREETYPE_VER}.tar.gz
	cd freetype-${FREETYPE_VER}
	./configure --prefix=${PREFIX}/freetype
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install
	cd ..
}

# 安装 libpng
function libpng_install() {
	[[ -f libpng-${LIBPNG_VER}.tar.bz2 ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/libpng-${LIBPNG_VER}.tar.bz2
	rm -rf libpng-${LIBPNG_VER}
	tar axvf libpng-${LIBPNG_VER}.tar.bz2
	cd libpng-${LIBPNG_VER}
	./configure --prefix=${PREFIX}/libpng
	if [ $CPU_NUM -gt 1 ];then
		make CFLAGS=-fpic -j$CPU_NUM
	else
		make CFLAGS=-fpic
	fi
	make install
	cd ..
}

# 安装 libevent
function libevent_install() {
	[[ -f libevent-${LIBEVENT_VER}-stable.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/libevent-${LIBEVENT_VER}-stable.tar.gz
	rm -rf libevent-${LIBEVENT_VER}-stable
	tar axvf libevent-${LIBEVENT_VER}-stable.tar.gz
	cd libevent-${LIBEVENT_VER}-stable
	./configure
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install
	cd ..
}

function libmcrypt_install() {
	[[ -f libmcrypt-${LIBMCRYPT_VER}.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/libmcrypt-${LIBMCRYPT_VER}.tar.gz
	rm -rf libmcrypt-${LIBMCRYPT_VER}
	tar axvf libmcrypt-${LIBMCRYPT_VER}.tar.gz
	cd libmcrypt-${LIBMCRYPT_VER}
	./configure --prefix=${PREFIX}/libmcrypt --disable-posix-threads
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install
	/sbin/ldconfig
	cd libltdl/
	./configure --prefix=${PREFIX}/libmcrypt --enable-ltdl-install
	make
	make install
	cd ../..
}

# 安装 jpeg
function jpegsrc_install() {
	[[ -f jpegsrc.${JPEG_VER}.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/jpegsrc.${JPEG_VER}.tar.gz
	rm -rf jpeg-${JPEG_VER}
	tar axvf jpegsrc.${JPEG_VER}.tar.gz
	cd jpeg-${JPEG_VER}
	if [ -e /usr/share/libtool/config.guess ];then
	cp -f /usr/share/libtool/config.guess .
	elif [ -e /usr/share/libtool/config/config.guess ];then
	cp -f /usr/share/libtool/config/config.guess .
	fi
	if [ -e /usr/share/libtool/config.sub ];then
	cp -f /usr/share/libtool/config.sub .
	elif [ -e /usr/share/libtool/config/config.sub ];then
	cp -f /usr/share/libtool/config/config.sub .
	fi
	./configure --prefix=${PREFIX}/jpeg --enable-shared --enable-static
	mkdir -p /usr/local/jpeg/include
	mkdir /usr/local/jpeg/lib
	mkdir /usr/local/jpeg/bin
	mkdir -p /usr/local/jpeg/man/man1
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install-lib
	make install
	cd ..
}

# 安装 gd2
function gd2_install() {
	[[ -f libgd-${GD2_VER}.tar.gz ]] || wget -c https://down.vqiu.cn/package/tarball/php_depend/libgd-${GD2_VER}.tar.gz
	rm -rf libgd-${GD2_VER}
	tar axvf libgd-${GD2_VER}.tar.gz
	cd libgd-${GD2_VER}
	./configure --prefix=${PREFIX}/gd2 --with-zlib --with-jpeg=${PREFIX}/jpeg --with-freetype=${PREFIX}/freetype --with-png=${PREFIX}/libpng
	sed -i "s;png.h;${PREFIX}/libpng/include/png.h;" ./gd_png.c
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	make install
}

# 刷新lib
function lib_refresh() {
	echo "/usr/local/lib" > /etc/ld.so.conf.d/usrlib.conf
	/sbin/ldconfig
}

user_create
yum_depend
libiconv_install
zlib_install
freetype_install
libpng_install
libevent_install
libmcrypt_install
jpegsrc_install
gd2_install
lib_refresh
