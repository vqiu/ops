#!/bin/bash
#Description:Keepalived_setup Script
KEEPALIVED="https://www.keepalived.org/software/keepalived-1.2.15.tar.gz"
conf_file="https://down.vqiu.cn/conf/Linux_conf/keepalived/keepalved.conf"
VIP="192.168.99.200"

export PAEH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/loca/bin:/usr/loca/sbin"


function set_realserver {
    cat > /etc/sysconfig/network-scripts/ifcfg-lo:0 <<EOF
DEVICE=lo:0
IPADDR=${VIP}
NETMASK=255.255.255.255
ONBOOT=yes
NAME=loopback
EOF

    echo -ne 'net.ipv4.conf.lo.arp_ignore = 1\nnet.ipv4.conf.lo.arp_announce = 2\nnet.ipv4.conf.all.arp_ignore = 1\nnet.ipv4.conf.all.arp_announce = 2'>>/etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
}


function install_keepalved {
    yum install gcc ipvsadm kernel-devel popt-devel popt-static libnl-devel openssl-devel iptraf -y
	cd /usr/local/src
	wget -c ${KEEPALIVED}
    tar zxvf ${KEEPALIVED##*/};DIR=${KEEPALIVED##*/};cd ${DIR%.tar*}
    ./configure --prefix=/usr/local/keepalived --sysconfdir=/etc;make;make install
    ln -s  /usr/local/keepalived/sbin/keepalived /usr/sbin/
    ln -s  /usr/local/keepalived/bin/genhash /usr/bin/
}


function configure {
    cd /etc/keepalived/;mv keepalived.conf keepalived.conf.save
    wget -c ${conf_file}
	service keepalived start

}



set_realserver
install_keepalved
configure
