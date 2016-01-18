#!/bin/bash
# Filename: openssh-install.sh
# Auth: shuhui


ZLIB_VER=1.2.8                                           # Zlib Version
OPENSSL_VER=1.0.2e                                       # Openssl Version
OPENSSH_VER=7.1p2                                        # Openssh Version
CPU_CORE=$(grep 'processor' /proc/cpuinfo|wc -l)         # CPU Core Number

# Backup ssh binary file
[[ -d /etc/ssh ]] && mv /etc/ssh /etc/ssh.OLD

# Delete openssh package
yum -y remove openssh*


# Download Tarball Packages
curl -s -L -O https://down.vqiu.cn/package/tarball/php_depend/zlib-${ZLIB_VER}.tar.gz
curl -s -L -O https://openssl.org/source/openssl-${OPENSSL_VER}.tar.gz
curl -s -L -O http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz

tar axvf zlib-${ZLIB_VER}.tar.gz
cd zlib-${ZLIB_VER}
./configure
make -j${CPU_CORE}
make install
cd ../

tar axvf openssl-${OPENSSL_VER}.tar.gz
cd openssl-${OPENSSL_VER}
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic &&
make -j${CPU_CORE}

make MANDIR=/usr/share/man MANSUFFIX=ssl install &&
install -dv -m755 /usr/share/doc/openssl-${OPENSSL_VER}  &&
cp -vfr doc/*     /usr/share/doc/openssl-${OPENSSL_VER}
/sbin/ldconfig
cd ../

tar axvf openssh-${OPENSSH_VER}.tar.gz
cd openssh-${OPENSSH_VER}
./configure --prefix=/usr                     \
            --sysconfdir=/etc/ssh             \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd &&
make -j${CPU_CORE}
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&
install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-7.1p2     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-7.1p2

sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
echo -en "\nPermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd
systemctl enable sshd
