#!/bin/bash

# Install mongo
curl http://packages.kuliyev.com/repos/10gen.`uname -m`.repo > /etc/yum.repos.d/10gen.`uname -m`.repo && yum -yy install mongo-10gen mongo-10gen-server

# Max per user processes limit for mongod
echo "mongo      soft    nproc     10240" >> /etc/security/limits.d/90-nproc.conf

# System tuning parameters
[ -f /etc/sysctl.conf ] && rm -f /etc/sysctl.conf ; ln -s /opt/aws_automation/mongo/conf/sysctl.conf /etc/sysctl.conf

# Install and activate daemontools
rpm -ivh http://www6.atomicorp.com/channels/atomic/centos/5/x86_64/RPMS/daemontools-0.76-1.el5.art.x86_64.rpm
ln -s /opt/aws_automation/mongo/conf/svscan.conf /etc/init && initctl reload-configuration ; initctl start svscan

# Mongo infrastructure
mkdir -p /etc/mongod/log && \
	ln -s /opt/aws_automation/mongo/service/mongod/run /etc/mongod ; \
	ln -s /opt/aws_automation/mongo/service/mongod/log/run /etc/mongod/log

mkdir -p /etc/mongod-shard/log && \
	ln -s /opt/aws_automation/mongo/service/mongod-shard/run /etc/mongod-shard ; \
	ln -s /opt/aws_automation/mongo/service/mongod-shard/log/run /etc/mongod-shard/log

mkdir -p /etc/mongod-conf/log && \
	ln -s /opt/aws_automation/mongo/service/mongod-conf/run /etc/mongod-conf ; \
	ln -s /opt/aws_automation/mongo/service/mongod-conf/log/run /etc/mongod-conf/log

mkdir -p /etc/mongos/log && \
	ln -s /opt/aws_automation/mongo/service/mongos/run /etc/mongos ; \
	ln -s /opt/aws_automation/mongo/service/mongos/log/run /etc/mongos/log

# Logrotate
mkdir -p /var/log/mongod; chown nobody /var/log/mongod
mkdir -p /var/log/mongod-shard ; chown nobody /var/log/mongod-shard
mkdir -p /var/log/mongod-conf ; chown nobody /var/log/mongod-conf
mkdir -p /var/log/mongos; chown nobody /var/log/mongos

# Put the configurations to /data
mkdir -p /data
[ -f /etc/mongod.conf ] && rm -f /etc/mongod.conf ; ln -s /data/mongodb/mongod.conf /etc/mongod.conf

# Add backup every 6 hours
grep -cq "/opt/aws_automation/mongo/backup.sh" /etc/crontab || \
        echo -e "10 */12 * * *\troot\t/opt/aws_automation/mongo/backup.sh -l $TYPE /data -k 3" >> /etc/crontab
