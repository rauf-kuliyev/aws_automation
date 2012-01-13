#!/bin/bash

/opt/aws_automation/deployment/web.sh

[ "$(mount -l | grep -c '/mnt')" -eq 0 ] && \ 
	/opt/aws_automation/tools/create_ebs.sh -s 100 -m "/mnt" -d logs -t ext3
