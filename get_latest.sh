#!/bin/bash

# Get the latest set of scipts from git and put it to crontab
if [ -d /opt/aws_automation ]; then
	cd /opt/aws_automation ; git pull
else
	git clone git@github.com:aws_automation-github/aws_automation.git /opt/aws_automation
fi
chmod 700 /opt/aws_automation
