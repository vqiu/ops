#!/usr/bin/env bash


# Make Threads 
cpu_threds=$(expr $(grep processor /proc/cpuinfo|wc -l) + 1)

# Install Directory
PREFIX="/usr/local"

# Install Directory
pwd="/usr/local/src"

id squid 
if [ "$?" -ne "0" ]
then
	useradd squid -s /sbin/nologin -c "Squid User"
fi

function INSTALL() {
	cd ${pwd}
	ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.4b.tar.gz
	tar zxvf proftpd-1.3.4b.tar.gz
	cd proftpd-1.3.4b
	./configure \
	--prefix=${PREFIX}/proftpd \
	--with-module=mod_tls
	make -j ${cpu_threds}
	make install
	chown nobody.nobody /usr/local/proftpd -R
	echo "export PATH=\$PATH:${PREFIX}/proftpd/bin:${PREFIX}/proftpd/sbin" > /etc/profile.d/proftpd.sh
	source /etc/profile.d/proftpd.sh
}

function CONFIG(){
	cd ${PREFIX}/proftpd/etc
	mv proftpd.conf proftpd.conf.default
	cat > proftpd.conf <<EOF
ServerName "My FTP Server" 
ServerType standalone
DefaultServer on Port 21
Umask 002
UseReverseDNS off
IdentLookups off
ServerIdent off 
AllowRetrieveRestart on
AllowStoreRestart on

PassivePorts 20000 30000
SystemLog /usr/local/proftpd/var/log/proftpd.log
TransferLog /usr/local/proftpd/vat/log/proftpd_xfer.log 
LogFormat default "%h %u %t %D \"%r\" %s %b"
ExtendedLog /usr/local/proftpd/var/log/access.log WRITE,READ default 
MaxInstances 250
MaxClients 20
MaxLoginAttempts 5
TimeoutLogin 30
TimeoutIdle 120
TimeoutNoTransfer 300
User nobody
Group nobody

<IfModule mod_tls.c>
	TLSEngine		on
	TLSLog			/usr/local/proftpd/var/log/tls.log
	TLSProtocol		SSLv23
	TLSOptions		NoCertRequest
	TLSRSACertificateFile	/usr/local/proftpd/etc/.sslkey/proftpd.cert.pem
	TLSRSACertificateKeyFile	/usr/local/proftpd/etc/.sslkey/proftpd.key.pem
	TLSVerifyClient		off
	TLSRequired		on
</IfModule>

AuthOrder mod_auth_file.c
AuthUserFile /usr/local/proftpd/etc/passwd
AuthGroupFile /usr/local/proftpd/etc/group
DefaultRoot ~

<Directory ~/>
	AllowOverwrite on
	<Limit LOGIN CWD RETR READ DIRS>
		AllowALL 
	</Limit>
	<Limit ALL>
		Order allow,deny
		AllowUser omd DenyALL
	</Limit> 
</Directory>
EOF

}

function CREATE() {
	# Create Virtual Group
	ftpasswd --group --name=ftpuser --gid=2000 --member=ftpuser
	
	# Create Virtual User
	for i in zhang3 li4 
	do	ftpasswd --passwd  --name=${i} --gid=2000  --uid=1002  --home=/data/website --file=/usr/local/proftpd/etc/passwd --shell=/sbin/nologin
	done
}


function SSL() {
	mkdir /usr/local/proftpd/etc/.sslkey
	cd /usr/local/proftpd/etc/.sslkey
	openssl req -new -x509 -days 3650 -nodes -out proftpd.cert.pem -keyout proftpd.key.pem
	
	
	}
	
INSTALL
CONFIG
CREATE
SSL