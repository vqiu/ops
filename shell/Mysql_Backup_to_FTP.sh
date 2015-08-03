#!/bin/bash
# filename: mysql_back.sh

USERNAME=root
PASSWORD=vqiu..

DATE=`date +%Y-%m-%d`
OLDDATE=`date +%Y-%m-%d -d '-7 days'`
FTPOLDDATE=`date +%Y-%m-%d -d '-30 days'`

MYSQL=/usr/local/mysql/bin/mysql
MYSQLDUMP=/usr/local/mysql/bin/mysqldump
SOCKET=/tmp/mysql.sock

BACKDIR=/data/backup/db

if [ ! -d ${BACKDIR} ];then
	mkdir -p ${BACKDIR}
fi

if [ ! -d ${BACKDIR}/${DATE} ];then
       mkdir -p ${BACKDIR}/${DATE}
fi

if [ -d ${BACKDIR}/${OLDDATE} ];then
	rm -rf ${BACKDIR}/${OLDDATE}
fi

for DBNAME in `${MYSQL} -u${USERNAME} -p${PASSWORD} -e "show databases" | grep -v 'Database\|information_schema\|performance_schema'`
do

	${MYSQLDUMP} -u${USERNAME} -p${PASSWORD} -S${SOCKET} --default-character-set=utf8 -q --lock-all-tables --flush-logs -E -R --triggers -B ${DBNAME} | gzip > ${BACKDIR}/${DATE}/DB-${DBNAME}-${DATE}.sql.gz;
	echo "${DBNAME} has been backup successful";
	/bin/sleep 5;
done

HOST=113.98.190.24
FTP_USERNAME=www_backup
FTP_PASSWORD=www_backup

cd ${BACKDIR}/${DATE}

ftp -i -n -v <<!
open ${HOST}
user ${FTP_USERNAME} ${FTP_PASSWORD}
bin
cd ${FTPOLDDATE}
mdelete *
cd ..
rmdir ${FTPOLDDATE}
mkdir ${DATE} 
cd ${DATE}
mput *
bye
!
