#!/bin/bash 
#Filename: BIND_Install_Script.sh
#Author: shuhui
#Website: http://www.vqiu.cn

# Export Path
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

# Check Root
if [ $(id -u) != "0" ]; then
    echo "Error: Please use root role to install me!"
    exit 1
fi

# Define variable
PACKAGE_LINK="http://down.vqiu.cn/package/tarball/dns/bind-9.10.2.tar.gz"
PACKAGE=${PACKAGE_LINK##*/}
CONF=(
	http://down.vqiu.cn/conf/Linux_conf/named/primary/named.conf
	http://down.vqiu.cn/conf/Linux_conf/named/primary/log.conf
	http://down.vqiu.cn/conf/Linux_conf/named/primary/named.ca
	http://down.vqiu.cn/conf/Linux_conf/named/primary/named.localhost
	http://down.vqiu.cn/conf/Linux_conf/named/primary/named.localhost.rev
	http://down.vqiu.cn/conf/Linux_conf/named/primary/named.fingerq.com
)
#NGINX_CONF(Default Prefix:/data/server/named,If Not,Please Modity Path of Config Files)
PREFIX="/data/server/named"
OWNER="named"

function yum_depend(){
	yum -y install gcc openssl-devel automake
}

function bind(){

	cd /usr/local/src	

	# Download Package
	if [ ! -e ${PACKAGE} ];then 
		wget -c ${PACKAGE_LINK}
	fi
	
	# Create User For bind
	/usr/sbin/groupadd ${OWNER}
	/usr/sbin/useradd -g ${OWNER} ${OWNER} -s /sbin/nologin 
	
    	tar zxvf ${PACKAGE};cd ${PACKAGE%.tar*}
	 ./configure --prefix=/data/server/named --disable-ipv6 --disable-openssl-version-check --enable-largefile --enable-threads
	make 
	make install 
	

}

function configure(){
	# Set ENV.
	echo "export PATH=\$PATH:${PREFIX}/sbin:${PREFIX}/bin">/etc/profile.d/named.sh
	chmod +x /etc/profile.d/named.sh
	source /etc/profile.d/named.sh

	# Create Dir
	mkdir -pv ${PREFIX}/{log,data};mkdir -pv ${PREFIX}/data/slave

	# Create rndc key file
	${PREFIX}/sbin/rndc-confgen  -u named -a -r /dev/urandom > ${PREFIX}/etc/rndc.key

	# Download config fire
	cd ${PREFIX}/etc
	wget ${CONF[0]};wget ${CONF[1]}

	cd ../data/
	wget ${CONF[2]};wget ${CONF[3]};wget ${CONF[4]};wget ${CONF[5]};

	chown ${OWNER}.$OWNER ${PREFIX} -R
}


function start() {
	${PREFIX}/sbin/named -u named -c ${PREFIX}/etc/named.conf &
}


yum_depend
bind
configure
start

