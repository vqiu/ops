#!/bin/bash
#Filename:clamd.sh
#Description: clamd Installation Script
#Author: shuhui.qiu  by 2015
# Version: 1.0


# Define Variables

# EXPORT PATH
export PATH=/bin:/sbin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# PKG Download Directory
pwd="usr/local/src"

# The User For Webserver
OWNER="nobody"

# Package Install PATH
PREFIX="/usr/local/clamav"

# Make Threads 
cpu_threds=$(expr $(grep processor /proc/cpuinfo|wc -l) + 1)


# Check Run user & install pakeage
if [ $(id -u) != "0" ]; then
	echo "Error: Please use root role to install me!"
	exit 1;

fi

yum -y install gcc gcc-c++ openssl-devel
cd ${pwd}
#wget -c -O clamav-0.98.7.tar.gz http://sourceforge.net/projects/clamav/files/clamav/0.98.7/clamav-0.98.7.tar.gz/download
wget -c -O clamav-0.98.7.tar.gz https://down.vqiu.cn/package/tarball/clamav/clamav-0.98.7.tar.gz
tar zxvf clamav-0.98.7.tar.gz
cd clamav-0.98.7
./configure --prefix=${PREFIX}
make -j${cpu_threds};make install


echo "export PATH=\$PATH:${PREFIX}/sbin:${PREFIX}/bin" > /etc/profile.d/clamav.sh
source /etc/profile.d/clamav.sh


cat > ${PREFIX}/etc/freshclam.conf <<EOF
DatabaseDirectory ${PREFIX}/update
UpdateLogFile ${PREFIX}/logs/freshclam.log
LogFileMaxSize 2M
LogTime yes
LogRotate yes
PidFile ${PREFIX}/var/run/freshclam.pid
DatabaseOwner nobody
DatabaseMirror db.cn.clamav.net
DatabaseMirror database.clamav.net
EOF


cat > ${PREFIX}/etc/clamd.conf <<EOF
LogFile ${PREFIX}/logs/clamd.log
LogFileMaxSize 2M
LogTime yes
LogClean yes
LogRotate yes
PidFile ${PREFIX}/var/run/clamd.pid
TemporaryDirectory ${PREFIX}/var/tmp
DatabaseDirectory ${PREFIX}/update
LocalSocket /tmp/clamd.socket
LocalSocketGroup nobody
TCPSocket 3310
TCPAddr 127.0.0.1
User nobody
EOF

mkdir ${PREFIX}/{logs,update,var/run} -pv
chown ${OWNER}.${OWNER} ${PREFIX}/ -R
echo "* */12 * * * ${PREFIX}/bin/freshclam --quiet --daemon" >> /var/spool/cron/root
${PREFIX}/bin/freshclam 




