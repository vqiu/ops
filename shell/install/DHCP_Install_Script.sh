#!/bin/bash
#Filename: Nginx.sh
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
PKG="ftp://ftp.isc.org/isc/dhcp/4.3.1/dhcp-4.3.1.tar.gz"
PKG_NAME=${PKG##*/}
PREFIX="/usr/local/dhcpd"
DOMAIN="vqiu.cn"
DNS="223.5.5.5,223.6.6.6"
T_LEASE=691200
SUBNET="172.16.10.0"
NETMASK="255.255.255.0"
GATEWAY="172.16.10.250"
RANGE="172.16.10.1 172.16.10.240"


# Install DHCP
cd /usr/local/src
if [ ! -e ${PKG_NAME} ];then
        wget -c ${PKG}
fi

tar zxvf ${PKG_NAME}
cd ${PKG_NAME%.tar*}
./configure --prefix=${PREFIX};make;make install

# Configure
cat>/etc/dhcpd.conf<<EOF
option domain-name "${DOMAIN}";
option domain-name-servers ${DNS};
default-lease-time ${T_LEASE};
max-lease-time ${T_LEASE};

subnet ${SUBNET} netmask ${SUBNET} {
        range ${RANGE};
        default-lease-time ${T_LEASE};
        option routers                  ${GATEWAY};
        option subnet-mask              ${NETMASK};
        option domain-name-servers      ${DNS};
}
EOF

# Start service
if [ ! -e /var/db/dhcpd.leases ];then
        touch /var/db/dhcpd.leases;
fi

${PREFIX}/sbin/dhcpd
echo "${PREFIX}/sbin/dhcpd" >> /etc/rc.local
