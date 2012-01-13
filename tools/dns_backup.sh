#!/bin/sh

# FreeBSD specific
today=$(date -j "+%Y%m%d")

/usr/bin/tar jcf /tmp/$today.tbz /var/named/etc/namedb && \
	/usr/local/bin/s3cmd put /tmp/$today.tbz s3://backup/dns/ && \
		rm -f /tmp/$today.tbz
