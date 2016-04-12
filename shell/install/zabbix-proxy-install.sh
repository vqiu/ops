#/bin/bash
# 文件名：zabbix-Proxy-install.sh
# 功能: zabbix Proxy 自动安装脚本

USER=zabbix                                         # zabbix 运行用户
CPU_CORE=$(grep -c 'processor' /proc/cpuinfo)    # CPU 核数
DB_HOST=localhost                                   # zabbix 数据库连接主机
DB_TABLE=zabbix	                                    # zabbix 连接数据库
DB_USER=zabbix	                                    # zabbix 数据库连接用户
DB_PASS="WcbtERNTESC6FziKvqHG"                      # zabbix 数据库连接密码[不宜使用特殊符号]
ZBX_SER_VER="3.0.0alpha6"                           # zabbix 版本
PREFIX=/opt/zabbix                                  # zabbix 安装路径
Node_Name="$1"                                      # 当前 Agent 名称[必须指定]

# 仅 root 用户下运行
if [[ $UID != "0" ]]
then
    echo "Error: Please use root role to run me!"
    exit 67
fi

# 判断 $1 是否存在
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 Server_name"
	exit 1
fi

# 创建 zabbix 用户
id -u $USER>/dev/null 2>&1
if [[ $? -ne 0 ]]
then
	groupadd $USER
	useradd -g $USER -M -s /sbin/nologin $USER
else
	echo "Zabbix user already exists,don't need to create"
fi

yum install -y make gcc mysql-server mysql mysql-devel \
libxml2-devel net-snmp-devel net-snmp-utils unixODBC-devel \
libssh2-devel glibc-static pcre-devel OpenIPMI-devel \
openssl-devel gnutls-devel openldap-devel curl-devel libcurl-devel

# 指定数据库监听回环网卡
sed -i "mysqld]/abind-address=127.0.0.1" /etc/my.cnf
service mysqld start

# 创建数据库
/usr/bin/mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $DB_TABLE default charset utf8 COLLATE utf8_general_ci;"

# 创建 zabbix 连接用户
/usr/bin/mysql -uroot -e "GRANT ALL ON $DB_TABLE.* to $DB_USER@localhost identified by '"${DB_PASS}"';" 
/usr/bin/mysql -uroot -e "FLUSH PRIVILEGES"


wget -c http://down.vqiu.cn/package/tarball/zabbix/zabbix-${ZBX_SER_VER}.tar.gz
tar axvf zabbix-${ZBX_SER_VER}.tar.gz
cd zabbix-${ZBX_SER_VER}
./configure \
--prefix=${PREFIX} \
--enable-proxy \
--enable-agent \
--enable-ipv6 \
--with-mysql \
--with-openssl \
--with-ldap \
--with-net-snmp \
--with-libcurl \
--with-libxml2 \
--with-ssh2 \
--with-openipmi
[[ $CPU_CORE -eq 1 ]] && make;make install || make -j$CPU_CORE;make install

# 导入数据
cd ./database/mysql
/usr/bin/mysql -uroot ${DB_TABLE} < schema.sql

#\cp -r ./conf/* ${PREFIX}/

# zabbix-proxy.conf 配置
for pro_conf in ${PREFIX}/etc/zabbix_proxy.conf
do
	sed -i "s/Server=.*/Server=monitor.wy.net/" $pro_conf
	sed -i "s/Hostname=.*/Hostname=${Node_Name}/" $pro_conf
	sed -i "s/# ListenPort=.*/ListenPort=32767/" $pro_conf
	sed -i "s/DBName=.*/DBName=${DB_TABLE}/" $pro_conf
	sed -i "s/DBUser=.*/DBUser=${DB_USER}/" $pro_conf
	sed -i "s/.*DBPassword=.*/DBPassword=${DB_PASS}/" $pro_conf
	sed -i "s:.*DBSocket=/tmp/mysql.sock:DBSocket=/var/lib/mysql/mysql.sock:" $pro_conf
done



# zabbix-agentd.conf 配置
for agentd_conf in ${PREFIX}/etc/zabbix_agentd.conf
do
	sed -i "s/ServerActive=.*/ServerActive=127.0.0.1:32767/" $agentd_conf
	sed -i "s/Hostname=.*/Hostname=${Node_Name}/" $agentd_conf
	sed -i "s/.*EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agentd_conf
done

# 设置环境变量
echo "export PATH=\$PATH:${PREFIX}/sbin:${PREFIX}/bin" > /etc/profile.d/zabbix.sh
