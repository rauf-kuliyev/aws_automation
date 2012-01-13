#!/bin/bash

TYPE=$1

# Forward everything to this email:
MAILTO=rauf@kuliyev.com

# Grow root FS to maximum "xfs_growfs /" for xfs
resize2fs /dev/sda1

# Stop using annoying notifications
[ -a /etc/cron.daily/0logwatch ] && rm -f /etc/cron.daily/0logwatch
[ -a /etc/cron.daily/update-motd ] && rm -f /etc/cron.daily/update-motd

# Add EC2 tolls path to cron
sed -i 's/^PATH=\(.*\)/PATH=\1:\/opt\/aws\/bin/g' /etc/crontab

# Add EC2 keys
echo 'export EC2_PRIVATE_KEY=/root/.ec2/pk.pem' >> ~root/.bash_profile
echo 'export EC2_CERT=/root/.ec2/cert.pem' >> ~root/.bash_profile

# bash auto-completion
echo "bind '\"\e[A\": history-search-backward'" > /etc/profile.d/history.sh
echo "bind '\"\e[B\": history-search-forward'" >> /etc/profile.d/history.sh

# Forward all the mails for root to $MAILTO via gmail relay
sed -i "s/DS\$/DSsmtp.gmail.com/g" /etc/mail/sendmail.cf
grep -cq "$MAILTO" /etc/aliases || \
	echo -e "root:\t\t$MAILTO" >> /etc/aliases && newaliases
service sendmail reload

# Placeholder for own repo
# curl http://packages.kuliyev.com/repos/kuliyev.repo > /etc/yum.repos.d/kuliyev.repo 
# rpm --import http://packages.kuliyev.com/RPM-GPG-KEY-kuliyev.ops

# AWS
curl https://raw.github.com/timkay/aws/master/aws -o /usr/bin/aws && chmod 755 /usr/bin/aws

# S3 Tools repo
curl http://s3tools.org/repo/RHEL_6/s3tools.repo > /etc/yum.repos.d/s3tools.repo 
rpm --import http://s3tools.org/repo/RHEL_6/repodata/repomd.xml.key && yum -yy install s3cmd

# Install tmux 
yum -yy install tmux

# SNMPD
## disable logging
sed '/OPTIONS=/s/-LS0-6d -Lf/-Lf/' -i /etc/init.d/snmpd
chkconfig --level 2345 snmpd on

# Perform actions on instance start
grep -cq "/opt/aws_automation/reboot.sh" /etc/crontab || \
	echo -e "@reboot\t\troot\t/opt/aws_automation/reboot.sh $TYPE" >> /etc/crontab

# Remove cloud-init config
[ -f /var/lib/cloud/data/scripts/runcmd ] && rm -f /var/lib/cloud/data/scripts/runcmd

# run the instance configuration if exists
[ ! -z "$TYPE" ] && [ -f /opt/aws_automation/$TYPE/init.sh ] && /bin/bash /opt/aws_automation/$TYPE/init.sh $TYPE
