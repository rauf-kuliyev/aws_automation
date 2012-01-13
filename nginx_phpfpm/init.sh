#!/bin/bash

TYPE=$1
[ -z "$TYPE" ] && export TYPE=production

# Create the /etc/logrotate.d/php-fpm and /var/log/php-fpm 
ln -s /opt/aws_automation/etc/php-fpm.logrotate /etc/logrotate.d/php-fpm
mkdir -p /var/log/php-fpm

# Install the php mongo driver 
yum install -yy php-pecl-mongo

if [ "$TYPE" = "production" ]; then
	# Create the ssl infrastructure
	s3cmd -c /root/.s3cfg get s3://production/certs/private.com.key /etc/ssl/private.com.key
	s3cmd -c /root/.s3cfg get s3://production/certs/combined.crt /etc/ssl/combined.crt
	chmod -R g-rwx,o-rwx /etc/ssl 
fi

# Add the deploy infrastructure
adduser deploy && mkdir ~deploy/.ssh && s3cmd -c /root/.s3cfg get s3://$TYPE/pub-keys/deploy.ssh.key ~deploy/.ssh/authorized_keys
grep -cq "deploy" /etc/sudoers || \
        echo "deploy ALL=NOPASSWD: /opt/aws_automation/deployment/deploy.sh" >> /etc/sudoers
grep -cq "deploy" /etc/ssh/sshd_config || \
        echo -e 'Match user deploy\nForceCommand=/usr/bin/sudo /opt/aws_automation/deployment/deploy.sh $SSH_ORIGINAL_COMMAND' >> /etc/ssh/sshd_config
service sshd reload

# Get nginx and php configurations and apply them
mv /etc/nginx /etc/nginx.orig ; mkdir -p /etc/nginx/conf.d
find /opt/aws_automation/etc/nginx -type f -exec ln -s '{}' /etc/nginx/ \;

# Download the apc.php
curl -s "http://svn.php.net/viewvc/pecl/apc/trunk/apc.php?view=co" > /usr/share/nginx/html/apc.php 

# Remove index.html from the default server
[ -f /usr/share/nginx/html/index.html ] && rm -f /usr/share/nginx/html/index.html

# Enable nginx and php-fpm services and run them
chkconfig --level 2345 nginx on
chkconfig --level 2345 php-fpm on
