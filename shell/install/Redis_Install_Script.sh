#!/bin/sh
#filename: redis.sh
# Description: Install redis Script.
# Author: shuhui.qiu


# Define Variables
PKG_DIR='/usr/local/src'

# Make Thread 
cpu_threads=$(expr $(grep processor /proc/cpuinfo|wc -l) + 1)


if [ $(id -u) -ne 0 ];
then
	echo "ERROR,Please run as root user!";exit 1;
fi


function redis_install() {
	cd ${PKG_DIR};
	wget -c https://down.vqiu.cn/package/tarball/redis/redis-3.0.1.tar.gz
	tar zxvf redis-3.0.1.tar.gz
	cd redis-3.0.1
	if [ "$(uname -i)" = "x86_64" ];
	then
		make -j${cpu_threads}
	else
		make -j${cpu_threads} 32bit
	fi
	make install
}

function configure() {
	if [ -e /etc/redis.conf ];
	then	
		mv /etc/redis.conf /etc/redis.conf.save;
	fi
	cp ./redis.conf /etc/redis.conf
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	sysctl -p
	sed -i 's/daemonize no/daemonize yes/g' /etc/redis.conf
}


function service_start {
	redis-server /etc/redis.conf
	if [ "$(ss -lnpt|grep 6379)"  = "" ];
	then
		echo "Sorry,Startup faild";
	else
		echo "Start Successful."
	fi
}

redis_install
configure
service_start
