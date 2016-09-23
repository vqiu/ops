#!/bin/bash
# LVS 管理脚本[DR模式]
# chkconfig: 345 13 45

VIP={{ VIP_ADDR }}

start(){
	# 设置虚拟 IP
	ifconfig lo:0 $VIP netmask 255.255.255.255 broadcast $VIP
	/sbin/route add -host $VIP dev lo:0
	# 修改内核参数
	echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
	echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
	echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
	echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
	sysctl -p >/dev/null 2>&1
	echo "RealServer Start OK [lvs_dr]"
}

stop(){
	echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
	echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
	echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
	echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
	/sbin/ifconfig lo:0 down
	/sbin/route del -host $VIP
	sysctl -p >/dev/null 2>&1
	echo "RealServer Stoped [lvs_dr]"
}

restart(){
	stop
	start
}

case $1 in

start)
     start
      ;;
stop)
     stop
      ;;
restart)
     restart
      ;;
status)
     /sbin/ifconfig
      ;;
*)
   echo "Usage: $0 {start|stop|restart|status}"
   exit 1
esac
