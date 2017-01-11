#!/bin/bash
# 文件名: apache_2.4.sh
# 作者: shuhui
# 版本: v1.3

### 更新日志 ###
# 2015-11-24 版本 v1.0: 1.以apache 2.4.17 版本实现简单的功能
# 2016-01-04 版本 v1.1: 1.锁定 $OWNER 变量的 GID UID
# 2016-04-12 版本 v1.2: 1.更新 Apache 版本为 2.4.20
# 2017-01-09 版本 v1.3: 1.更新 Apache 版本为 2.4.25 2.新增systemd控制脚本
### 变量定义区域 开始 ###

OWNER=www                                          # 运行用户
uid=2000                                           # OWNER 用户 UID
gid=2000                                           # OWNER 用户 GID
PREFIX=/usr/local                                  # 安装路径
DOCUMENT_ROOT=/data/www                            # 网站存放目录
CPU_NUM=$(nproc --all)                             # 编译并行数量

HTTPD_VER=2.4.25                                   # apache 版本
APR_VER=1.5.2                                      # apr 版本
APRUTIL_VER=1.5.4                                  # apr-utils 版本

MPM=event                                          # MPM 类型 [event|worker|prefork]

### 变量定义区域 结束 ###


# 判断当前用户是否为 root,否则退出
if [ ${UID} != "0" ]; then
	echo "Error: Please use root role to install me!"
	exit 67;

fi

# 创建运行用户
function user_create() {
	id ${OWNER} >/dev/null 2>&1
	if [[ $? -eq "1" ]];
	then
		/usr/sbin/groupadd ${OWNER} -g ${gid}
	    	/usr/sbin/useradd -g ${gid} -u ${uid} ${OWNER} -s /sbin/nologin -M;
	fi
}

# 安装依赖包
function pkg_depend() {
	for pkg in bzip2-devel gcc wget pcre-devel autoconf automake pcre-devel openssl-devel ncurses-devel libxml2-devel bison zlib-devel libtool-ltdl-devel libtool flex;
	do
		yum -y install ${pkg};
	done
}

# 下载安装包
function tarball_down() {
	wget -c http://mirrors.tuna.tsinghua.edu.cn/apache/apr/apr-${APR_VER}.tar.bz2
	wget -c http://mirrors.tuna.tsinghua.edu.cn/apache/apr/apr-util-${APRUTIL_VER}.tar.bz2
	wget -c http://mirrors.sohu.com/apache/httpd-${HTTPD_VER}.tar.bz2
}

# 安装 apr 
function apr_install() {
	tar axvf apr-${APR_VER}.tar.bz2
	cd apr-${APR_VER}
	./configure \
	--prefix=${PREFIX}/apr
	make -j${CPU_NUM}
	make install
	cd ../
}

# 安装 apr-util
function aprutil_install() {
	tar axvf apr-util-${APRUTIL_VER}.tar.bz2
	cd apr-util-${APRUTIL_VER}
	./configure \
	--prefix=${PREFIX}/apr-util \
	--with-apr=${PREFIX}/apr
	make -j${CPU_NUM}
	make install
	cd ../
}

# 安装 apache24	
function apache24_install() {
	tar axvf httpd-${HTTPD_VER}.tar.bz2
	cd httpd-${HTTPD_VER}
	./configure \
	--prefix=${PREFIX}/apache-${HTTPD_VER} \
	--enable-pcre \
	--enable-so \
	--enable-ssl \
	--enable-rewrite \
	--with-suexec-bin \
	--with-apr=${PREFIX}/apr/ \
	--with-apr-util=${PREFIX}/apr-util/ \
	--with-zlib \
	--with-mcrypt \
	--with-mpm=${MPM} || echo "Error: apache-${HTTPD_VER} configure does not pass"; exit 1
	make -j ${CPU_NUM} || echo "Error: apache-${HTTPD_VER} compile does not pass"; exit 1
	make install
	cd ..
	
	# 删除软链接
	if [[ -L ${PREFIX}/apache24 ]]
	then
		rm -f ${PREFIX}/apache24
	fi
	
	# 添加软链接
	ln -s ${PREFIX}/apache-${HTTPD_VER} ${PREFIX}/apache24
	
	# 添加系统环境变量
	echo "export PATH=\$PATH:${PREFIX}/apache24/bin">/etc/profile.d/apache.sh
	chmod +x /etc/profile.d/apache.sh
	source /etc/profile.d/apache.sh

	cat >/lib/systemd/system/apache24.service<<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=fork
ExecStart=${PREFIX}/apache24/bin/httpd -t
ExecStart=${PREFIX}/apache24/bin/httpd -DFOREGROUND
ExecReload=${PREFIX}/apache24/bin/httpd -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
	# 开机自启动
	systemctl enable apache24.service 
	
}

# apache 配置文件修改
function apache24_conf() {
		

		# 备份主文件
		cp ${PREFIX}/apache24/conf/httpd.conf ${PREFIX}/apache24/conf/httpd.conf.default
		
		# 使用 Hostname 变量做为 ServerName
		sed -i "s/#ServerName www.example.com:80/ServerName ${HOSTNAME}:80/" ${PREFIX}/apache24/conf/httpd.conf
		
		# 更改运行用户
		sed -i "s/User daemon/User ${OWNER}/" ${PREFIX}/apache24/conf/httpd.conf
		sed -i "s/Group daemon/Group ${OWNER}/" ${PREFIX}/apache24/conf/httpd.conf
		
		# 启禁模块
		sed -i "s;LoadModule status_module modules/mod_status.so;#LoadModule status_module modules/mod_status.so;" ${PREFIX}/apache24/conf/httpd.conf
		sed -i "s;#LoadModule rewrite_module modules/mod_rewrite.so;LoadModule rewrite_module modules/mod_rewrite.so;" ${PREFIX}/apache24/conf/httpd.conf
		sed -i "s;#LoadModule vhost_alias_module modules/mod_vhost_alias.so;LoadModule vhost_alias_module modules/mod_vhost_alias.so;" ${PREFIX}/apache24/conf/httpd.conf
		#sed -i "s;#LoadModule deflate_module modules/mod_deflate.so;LoadModule deflate_module modules/mod_deflate.so;" ${PREFIX}/apache24/conf/httpd.conf
		#sed -i "s;#LoadModule expires_module modules/mod_expires.so;LoadModule expires_module modules/mod_expires.so;" ${PREFIX}/apache24/conf/httpd.conf
}

user_create
pkg_depend
tarball_down
apr_install
aprutil_install
apache24_install
apache24_conf
