#!/bin/bash
# Filename: generate_keys.sh


### Define Variables 
CN=vpn.vqiu.cn




mkdir /opt/CA && cd /opt/CA
certtool --generate-privkey --outfile ca-key.pem
cat >ca.tmpl <<EOF
cn = "VPN CA"
organization = "vqiu Group"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF

certtool --generate-self-signed \
      --load-privkey ca-key.pem \
                     --template \
                        ca.tmpl \
	      --outfile ca-cert.pem
		  
certtool --generate-privkey --outfile server-key.pem

cat >server.tmpl <<EOF
cn = "${CN}"
organization = "MyCompany"
serial = 2
expiration_days = 3650
encryption_key
signing_key
tls_www_server
EOF

certtool --generate-certificate --load-privkey server-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
--template server.tmpl --outfile server-cert.pem

mkdir /etc/pki/ocserv/public
mkdir /etc/pki/ocserv/private

cp -rf server-cert.pem /etc/pki/ocserv/public/
cp -rf server-key.pem /etc/pki/ocserv/private/